from __future__ import annotations
import csv
from pathlib import Path
from app.schemas.habitat import HabitatFeatureInput
from app.services.habitat_model_service import get_habitat_model_health, score_habitat

ORCA_ROOT = Path(__file__).resolve().parents[2]
FEATURES_CSV = ORCA_ROOT / "data" / "processed" / "training_features.csv"

def _f(value):
    if value in {None, "", "nan", "NaN"}: return None
    return float(value)

def main():
    print("MODEL HEALTH")
    print(get_habitat_model_health().model_dump_json(indent=2))
    if not FEATURES_CSV.exists():
        raise FileNotFoundError(f"Missing {FEATURES_CSV}")
    with FEATURES_CSV.open("r", encoding="utf-8", newline="") as handle:
        for row in csv.DictReader(handle):
            req = ["depth_m","bathy_slope_m_per_km","month_sin","month_cos","doy_sin","doy_cos","sst_c","chl_mg_m3","wind_speed_ms"]
            if any(row.get(x) in {None,"","nan","NaN"} for x in req): continue
            features = HabitatFeatureInput(
                depth_m=float(row["depth_m"]), bathy_slope_m_per_km=float(row["bathy_slope_m_per_km"]),
                month_sin=float(row["month_sin"]), month_cos=float(row["month_cos"]),
                doy_sin=float(row["doy_sin"]), doy_cos=float(row["doy_cos"]),
                sst_c=float(row["sst_c"]), sst_anom_c=_f(row.get("sst_anom_c")),
                sst_error_c=_f(row.get("sst_error_c")), sst_local_range_c=_f(row.get("sst_local_range_c")),
                chl_mg_m3=float(row["chl_mg_m3"]), log_chl=_f(row.get("log_chl")),
                chl_local_range=_f(row.get("chl_local_range")), wind_speed_ms=float(row["wind_speed_ms"]),
                eastward_wind_ms=_f(row.get("eastward_wind_ms")), northward_wind_ms=_f(row.get("northward_wind_ms")),
            )
            print("\nTEST SAMPLE")
            print({k: row.get(k) for k in ["sample_id","label","date","latitude","longitude"]})
            print("\nMODEL RESULT")
            print(score_habitat(features).model_dump_json(indent=2))
            return
    raise RuntimeError("No complete row was found in training_features.csv.")

if __name__ == "__main__":
    main()
