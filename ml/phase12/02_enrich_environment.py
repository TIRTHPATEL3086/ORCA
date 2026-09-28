from __future__ import annotations

from io import StringIO
from pathlib import Path
import math
import time

import numpy as np
import pandas as pd
import requests
from scipy.spatial import cKDTree

from config import (
    CACHE,
    CHL_STRIDE,
    INCOIS_CHL_BASE,
    INCOIS_WIND_BASE,
    LAT_MAX,
    LAT_MIN,
    LON_MAX,
    LON_MIN,
    MAX_CHL_TIME_GAP_DAYS,
    MAX_SST_TIME_GAP_DAYS,
    MAX_WIND_TIME_GAP_DAYS,
    NOAA_OISST_BASE,
    PROCESSED,
)


def _request_csv(url: str, retries: int = 4) -> pd.DataFrame:
    last_error = None

    for attempt in range(retries):
        try:
            response = requests.get(
                url,
                timeout=90,
                headers={
                    "User-Agent": "ORCA-Hackathon-Research/1.0",
                    "Accept": "text/csv",
                },
            )

            if response.status_code >= 400:
                raise RuntimeError(
                    f"HTTP {response.status_code}: {response.text[:250]}"
                )

            # ERDDAP .csv responses contain a second row with units.
            return pd.read_csv(
                StringIO(response.text),
                skiprows=[1],
            )
        except Exception as exc:
            last_error = exc
            time.sleep(2 ** attempt)

    raise RuntimeError(
        f"ERDDAP request failed after {retries} attempts: {last_error}"
    )


def _cache_path(kind: str, date: pd.Timestamp) -> Path:
    folder = CACHE / kind
    folder.mkdir(parents=True, exist_ok=True)
    return folder / f"{date.strftime('%Y-%m-%d')}.csv"


def _load_or_fetch(kind: str, date: pd.Timestamp) -> pd.DataFrame:
    target = _cache_path(kind, date)

    if target.exists() and target.stat().st_size > 20:
        return pd.read_csv(target)

    date0 = date.strftime("%Y-%m-%d")

    if kind == "chl":
        # Oceansat-2 OCM is ~0.04°. A stride of 5 produces a ~0.20°
        # working grid, enough for v1 habitat modelling and dramatically
        # smaller than downloading the 12 GB archive.
        query = (
            f"CHL[({date0}T00:00:00Z)]"
            f"[({LAT_MIN}):{CHL_STRIDE}:({LAT_MAX})]"
            f"[({LON_MIN}):{CHL_STRIDE}:({LON_MAX})]"
        )
        url = f"{INCOIS_CHL_BASE}?{query}"

    elif kind == "wind":
        dims = (
            f"[({date0}T12:00:00Z)][(last)]"
            f"[({LAT_MIN}):({LAT_MAX})]"
            f"[({LON_MIN}):({LON_MAX})]"
        )
        query = ",".join(
            [
                f"wind_speed{dims}",
                f"eastward_wind{dims}",
                f"northward_wind{dims}",
            ]
        )
        url = f"{INCOIS_WIND_BASE}?{query}"

    elif kind == "sst":
        dims = (
            f"[({date0}T12:00:00Z)][(last)]"
            f"[({LAT_MIN}):({LAT_MAX})]"
            f"[({LON_MIN}):({LON_MAX})]"
        )
        query = ",".join(
            [
                f"sst{dims}",
                f"anom{dims}",
                f"err{dims}",
            ]
        )
        url = f"{NOAA_OISST_BASE}?{query}"

    else:
        raise ValueError(kind)

    print(f"Downloading small {kind.upper()} regional subset for {date0} ...")
    df = _request_csv(url)
    df.to_csv(target, index=False)
    return df


def _standardize_grid(df: pd.DataFrame) -> pd.DataFrame:
    rename = {}

    for column in df.columns:
        low = column.lower()

        if low in {"lat", "latitude"}:
            rename[column] = "latitude"
        elif low in {"lon", "longitude"}:
            rename[column] = "longitude"
        elif low == "time":
            rename[column] = "time"

    df = df.rename(columns=rename)

    for column in df.columns:
        if column not in {"time"}:
            df[column] = pd.to_numeric(
                df[column],
                errors="coerce",
            )

    if "time" in df.columns:
        df["time"] = pd.to_datetime(
            df["time"],
            errors="coerce",
            utc=True,
        )

    return df


def _valid_grid(kind: str, df: pd.DataFrame) -> pd.DataFrame:
    df = _standardize_grid(df)

    if kind == "chl":
        df["CHL"] = pd.to_numeric(df.get("CHL"), errors="coerce")
        df = df[
            df["CHL"].between(0.001, 100.0)
        ].copy()

    elif kind == "wind":
        for c in [
            "wind_speed",
            "eastward_wind",
            "northward_wind",
        ]:
            df[c] = pd.to_numeric(df.get(c), errors="coerce")

        df = df[
            df["wind_speed"].between(0, 80)
            & df["eastward_wind"].between(-80, 80)
            & df["northward_wind"].between(-80, 80)
        ].copy()

    elif kind == "sst":
        for c in ["sst", "anom", "err"]:
            df[c] = pd.to_numeric(df.get(c), errors="coerce")

        df = df[
            df["sst"].between(-3, 45)
        ].copy()

    return df


def _date_gap_days(
    grid: pd.DataFrame,
    requested_date: pd.Timestamp,
) -> float | None:
    if "time" not in grid.columns or grid["time"].dropna().empty:
        return None

    actual = grid["time"].dropna().iloc[0]
    requested = pd.Timestamp(
        requested_date.date(),
        tz="UTC",
    )

    return abs(
        (actual - requested).total_seconds()
    ) / 86400.0


def _nearest_feature(
    grid: pd.DataFrame,
    lat: float,
    lon: float,
    columns: list[str],
    radius_deg: float,
) -> dict:
    if grid.empty:
        return {
            c: np.nan
            for c in columns
        } | {"local_range": np.nan, "nearest_distance_deg": np.nan}

    coords = grid[
        ["latitude", "longitude"]
    ].to_numpy(dtype=float)

    tree = cKDTree(coords)

    distance, index = tree.query(
        [lat, lon],
        k=1,
    )

    if not np.isfinite(distance) or distance > radius_deg:
        return {
            c: np.nan
            for c in columns
        } | {"local_range": np.nan, "nearest_distance_deg": float(distance)}

    row = grid.iloc[int(index)]
    result = {
        c: float(row[c])
        if pd.notna(row[c])
        else np.nan
        for c in columns
    }

    nearby = tree.query_ball_point(
        [lat, lon],
        r=radius_deg,
    )

    primary = columns[0]
    values = pd.to_numeric(
        grid.iloc[nearby][primary],
        errors="coerce",
    ).dropna()

    result["local_range"] = (
        float(values.max() - values.min())
        if len(values) >= 2
        else np.nan
    )
    result["nearest_distance_deg"] = float(distance)

    return result


def _extract_with_fallback(
    kind: str,
    date: pd.Timestamp,
    lat: float,
    lon: float,
) -> dict:
    if kind == "chl":
        offsets = [0, -1, 1, -2, 2, -3, 3]
        columns = ["CHL"]
        max_gap = MAX_CHL_TIME_GAP_DAYS
        radius = 0.35

    elif kind == "wind":
        offsets = [0, -1, 1]
        columns = [
            "wind_speed",
            "eastward_wind",
            "northward_wind",
        ]
        max_gap = MAX_WIND_TIME_GAP_DAYS
        radius = 0.40

    elif kind == "sst":
        offsets = [0, -1, 1]
        columns = ["sst", "anom", "err"]
        max_gap = MAX_SST_TIME_GAP_DAYS
        radius = 0.40

    else:
        raise ValueError(kind)

    for offset in offsets:
        requested = date + pd.Timedelta(days=offset)

        try:
            grid = _valid_grid(
                kind,
                _load_or_fetch(
                    kind,
                    requested,
                ),
            )
        except Exception as exc:
            print(
                f"WARNING: {kind} {requested.date()} failed: {exc}"
            )
            continue

        gap = _date_gap_days(
            grid,
            date,
        )

        if gap is not None and gap > max_gap:
            continue

        result = _nearest_feature(
            grid,
            lat,
            lon,
            columns,
            radius,
        )

        if any(
            pd.notna(result[c])
            for c in columns
        ):
            result["time_offset_days"] = offset
            return result

    return {
        c: np.nan
        for c in columns
    } | {
        "local_range": np.nan,
        "nearest_distance_deg": np.nan,
        "time_offset_days": np.nan,
    }


def main():
    source = PROCESSED / "samples_base.csv"

    if not source.exists():
        raise FileNotFoundError(
            "Run 01_prepare_samples.py first."
        )

    samples = pd.read_csv(source)
    samples["date"] = pd.to_datetime(
        samples["date"]
    )

    rows = []

    for index, row in enumerate(
        samples.itertuples(),
        start=1,
    ):
        print(
            f"[{index}/{len(samples)}] "
            f"{row.date.date()} "
            f"{row.latitude:.3f},{row.longitude:.3f}"
        )

        chl = _extract_with_fallback(
            "chl",
            row.date,
            row.latitude,
            row.longitude,
        )
        wind = _extract_with_fallback(
            "wind",
            row.date,
            row.latitude,
            row.longitude,
        )
        sst = _extract_with_fallback(
            "sst",
            row.date,
            row.latitude,
            row.longitude,
        )

        rows.append(
            {
                "sample_id": row.sample_id,
                "chl_mg_m3": chl["CHL"],
                "log_chl": (
                    math.log1p(chl["CHL"])
                    if pd.notna(chl["CHL"])
                    else np.nan
                ),
                "chl_local_range": chl["local_range"],
                "chl_time_offset_days": chl["time_offset_days"],
                "sst_c": sst["sst"],
                "sst_anom_c": sst["anom"],
                "sst_error_c": sst["err"],
                "sst_local_range_c": sst["local_range"],
                "sst_time_offset_days": sst["time_offset_days"],
                "wind_speed_ms": wind["wind_speed"],
                "eastward_wind_ms": wind["eastward_wind"],
                "northward_wind_ms": wind["northward_wind"],
                "wind_time_offset_days": wind["time_offset_days"],
            }
        )

    env = pd.DataFrame(rows)
    merged = samples.merge(
        env,
        on="sample_id",
        how="left",
        validate="one_to_one",
    )

    target = PROCESSED / "training_features.csv"
    merged.to_csv(target, index=False)

    print("\nEnvironmental completeness:")
    for column in [
        "chl_mg_m3",
        "sst_c",
        "wind_speed_ms",
    ]:
        percentage = (
            merged[column].notna().mean()
            * 100.0
        )
        print(
            f"  {column}: {percentage:.1f}%"
        )

    print(f"\nSaved: {target}")


if __name__ == "__main__":
    main()
