from __future__ import annotations

import math
import random

import numpy as np
import pandas as pd
from scipy.io import netcdf_file

from config import (
    BACKGROUND_PER_PRESENCE,
    CMLRE_CSV,
    FISH_CLASSES,
    GEBCO_NC,
    LAT_MAX,
    LAT_MIN,
    LON_MAX,
    LON_MIN,
    PROCESSED,
    RANDOM_SEED,
    START_YEAR,
    END_YEAR,
)


EARTH_RADIUS_KM = 6371.0088


def _destination(
    lat: float,
    lon: float,
    bearing_deg: float,
    distance_km: float,
) -> tuple[float, float]:
    bearing = math.radians(bearing_deg)
    d = distance_km / EARTH_RADIUS_KM
    lat1 = math.radians(lat)
    lon1 = math.radians(lon)

    lat2 = math.asin(
        math.sin(lat1) * math.cos(d)
        + math.cos(lat1) * math.sin(d) * math.cos(bearing)
    )
    lon2 = lon1 + math.atan2(
        math.sin(bearing) * math.sin(d) * math.cos(lat1),
        math.cos(d) - math.sin(lat1) * math.sin(lat2),
    )

    return math.degrees(lat2), ((math.degrees(lon2) + 540) % 360) - 180


class GebcoSampler:
    def __init__(self, path):
        self.nc = netcdf_file(str(path), "r", mmap=False)
        self.lat = self.nc.variables["lat"].data
        self.lon = self.nc.variables["lon"].data
        self.elevation = self.nc.variables["elevation"].data

    def close(self):
        self.nc.close()

    def _indices(self, lat, lon):
        i = int(np.abs(self.lat - lat).argmin())
        j = int(np.abs(self.lon - lon).argmin())
        return i, j

    def elevation_m(self, lat, lon):
        i, j = self._indices(lat, lon)
        return float(self.elevation[i, j])

    def features(self, lat, lon):
        i, j = self._indices(lat, lon)
        z = float(self.elevation[i, j])
        depth = max(0.0, -z)

        i0 = max(0, i - 1)
        i1 = min(len(self.lat) - 1, i + 1)
        j0 = max(0, j - 1)
        j1 = min(len(self.lon) - 1, j + 1)

        dz_lat = float(self.elevation[i1, j] - self.elevation[i0, j])
        dz_lon = float(self.elevation[i, j1] - self.elevation[i, j0])

        dlat_km = max(
            0.01,
            abs(float(self.lat[i1] - self.lat[i0])) * 111.32,
        )
        dlon_km = max(
            0.01,
            abs(float(self.lon[j1] - self.lon[j0]))
            * 111.32
            * math.cos(math.radians(lat)),
        )

        slope_m_per_km = math.sqrt(
            (dz_lat / dlat_km) ** 2
            + (dz_lon / dlon_km) ** 2
        )

        return z, depth, slope_m_per_km


def load_presence_points():
    if not CMLRE_CSV.exists():
        raise FileNotFoundError(
            f"Missing {CMLRE_CSV}\n"
            "Copy cmlre_voucher_specimens_2025.csv there first."
        )

    df = pd.read_csv(CMLRE_CSV, low_memory=False)

    df["date"] = pd.to_datetime(
        df["eventDate"],
        errors="coerce",
        utc=True,
    ).dt.tz_convert(None)

    df["latitude"] = pd.to_numeric(
        df["decimalLatitude"],
        errors="coerce",
    )
    df["longitude"] = pd.to_numeric(
        df["decimalLongitude"],
        errors="coerce",
    )

    df = df[
        df["class"].isin(FISH_CLASSES)
        & df["date"].notna()
        & df["latitude"].between(LAT_MIN, LAT_MAX)
        & df["longitude"].between(LON_MIN, LON_MAX)
        & df["date"].dt.year.between(START_YEAR, END_YEAR)
    ].copy()

    # Avoid repeated identical biological observations dominating the model.
    df = df.drop_duplicates(
        subset=[
            "date",
            "latitude",
            "longitude",
            "scientificName",
        ]
    )

    out = pd.DataFrame(
        {
            "sample_id": [
                f"P{i:05d}"
                for i in range(len(df))
            ],
            "label": 1,
            "date": df["date"].dt.strftime("%Y-%m-%d"),
            "latitude": df["latitude"].astype(float),
            "longitude": df["longitude"].astype(float),
            "scientific_name": df["scientificName"].fillna("Unknown"),
            "source": "CMLRE voucher specimen / IndOBIS",
        }
    )

    return out.reset_index(drop=True)


def make_background(presence, bathy):
    rng = random.Random(RANDOM_SEED)
    rows = []

    for _, row in presence.iterrows():
        made = 0
        attempts = 0

        while made < BACKGROUND_PER_PRESENCE and attempts < 200:
            attempts += 1

            # Background is generated near the observed marine sampling area,
            # not randomly across the whole ocean.
            bearing = rng.uniform(0, 360)
            distance = rng.uniform(25, 140)

            lat, lon = _destination(
                float(row.latitude),
                float(row.longitude),
                bearing,
                distance,
            )

            if not (
                LAT_MIN <= lat <= LAT_MAX
                and LON_MIN <= lon <= LON_MAX
            ):
                continue

            elevation = bathy.elevation_m(lat, lon)

            # Ocean only. Keep away from the immediate shoreline.
            if elevation >= -5:
                continue

            rows.append(
                {
                    "sample_id": f"B{len(rows):05d}",
                    "label": 0,
                    "date": row.date,
                    "latitude": lat,
                    "longitude": lon,
                    "scientific_name": "",
                    "source": "controlled_background",
                }
            )
            made += 1

    return pd.DataFrame(rows)


def main():
    PROCESSED.mkdir(parents=True, exist_ok=True)

    if not GEBCO_NC.exists():
        raise FileNotFoundError(
            f"Missing {GEBCO_NC}\n"
            "Extract only gebco_2026_n25.0_s5.0_w65.0_e98.0.nc "
            "from your GEBCO ZIP into data/raw/bathymetry/."
        )

    presence = load_presence_points()

    bathy = GebcoSampler(GEBCO_NC)

    try:
        background = make_background(presence, bathy)
        samples = pd.concat(
            [presence, background],
            ignore_index=True,
        )

        elevation = []
        depth = []
        slope = []

        for row in samples.itertuples():
            e, d, s = bathy.features(
                row.latitude,
                row.longitude,
            )
            elevation.append(e)
            depth.append(d)
            slope.append(s)

        samples["elevation_m"] = elevation
        samples["depth_m"] = depth
        samples["bathy_slope_m_per_km"] = slope
    finally:
        bathy.close()

    dt = pd.to_datetime(samples["date"])
    doy = dt.dt.dayofyear
    samples["month"] = dt.dt.month
    samples["month_sin"] = np.sin(
        2 * np.pi * samples["month"] / 12.0
    )
    samples["month_cos"] = np.cos(
        2 * np.pi * samples["month"] / 12.0
    )
    samples["doy_sin"] = np.sin(
        2 * np.pi * doy / 365.25
    )
    samples["doy_cos"] = np.cos(
        2 * np.pi * doy / 365.25
    )

    target = PROCESSED / "samples_base.csv"
    samples.to_csv(target, index=False)

    print(f"Presence records: {len(presence)}")
    print(f"Background records: {len(background)}")
    print(f"Total samples: {len(samples)}")
    print(f"Saved: {target}")


if __name__ == "__main__":
    main()
