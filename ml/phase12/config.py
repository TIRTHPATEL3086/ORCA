from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

RAW = ROOT / "data" / "raw"
PROCESSED = ROOT / "data" / "processed"
CACHE = ROOT / "data" / "cache" / "environment"
ARTIFACTS = ROOT / "ml" / "artifacts"

CMLRE_CSV = RAW / "occurrences" / "cmlre_voucher_specimens_2025.csv"
INDOBIS_CSV = RAW / "occurrences" / "indobis_occurrences.csv"
GEBCO_NC = RAW / "bathymetry" / "gebco_2026_n25.0_s5.0_w65.0_e98.0.nc"

LAT_MIN = 5.0
LAT_MAX = 25.0
LON_MIN = 65.0
LON_MAX = 98.0

START_YEAR = 2011
END_YEAR = 2018

BACKGROUND_PER_PRESENCE = 2
RANDOM_SEED = 42

# We deliberately request small regional/day subsets instead of downloading
# the 10+ GB full environmental archives.
CHL_STRIDE = 5  # Oceansat-2 ~0.04° native -> ~0.20° working grid
MAX_CHL_TIME_GAP_DAYS = 3
MAX_SST_TIME_GAP_DAYS = 1
MAX_WIND_TIME_GAP_DAYS = 1

INCOIS_CHL_BASE = (
    "https://erddap.incois.gov.in/erddap/griddap/"
    "incois_oceansat2_datasets.csv"
)
INCOIS_WIND_BASE = (
    "https://erddap.incois.gov.in/erddap/griddap/"
    "ascat_daily_datasets.csv"
)
NOAA_OISST_BASE = (
    "https://coastwatch.pfeg.noaa.gov/erddap/griddap/"
    "ncdcOisst21Agg_LonPM180.csv"
)

FISH_CLASSES = {
    "Teleostei",
    "Elasmobranchii",
    "Holocephali",
    "Coelacanthi",
    "Myxini",
    "Petromyzonti",
}
