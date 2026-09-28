"""Memory-light land/water lookup for ORCA's operating region.

Drop-in replacement for global_land_mask.globe.is_ocean, using the same
1 km GLOBE grid and indexing but only the Indian Ocean window, kept
bit-packed (~5 MB in memory instead of the package's 933 MB world grid).
Regenerate the data file with scripts/build_land_mask.py.
"""

from functools import lru_cache
from pathlib import Path

import numpy as np


# Northern Indian Ocean: comfortably covers ORCA's 5–25°N, 65–98°E area.
LAT_MIN, LAT_MAX = -10.0, 35.0
LON_MIN, LON_MAX = 50.0, 110.0

MASK_PATH = Path(__file__).resolve().parents[1] / "data" / "land_mask_indian_ocean.npz"


@lru_cache(maxsize=1)
def _mask():
    with np.load(MASK_PATH) as data:
        return {key: data[key] for key in data.files}


def is_ocean(latitude: float, longitude: float) -> bool:
    """True when the point is water on the 1 km GLOBE land mask.

    Points outside the covered region are treated as open ocean.
    """
    m = _mask()

    if not (LAT_MIN <= latitude <= LAT_MAX and LON_MIN <= longitude <= LON_MAX):
        return True

    # Same index arithmetic as global_land_mask.globe.
    lat = min(max(latitude, float(m["lat_min"])), float(m["lat_max"]))
    lon = min(max(longitude, float(m["lon_min"])), float(m["lon_max"]))
    row = int((lat - float(m["lat0"])) / float(m["dlat"])) - int(m["row_offset"])
    col = int((lon - float(m["lon0"])) / float(m["dlon"])) - int(m["col_offset"])

    bits = m["mask_bits"]
    row = min(max(row, 0), bits.shape[0] - 1)
    col = min(max(col, 0), int(m["width"]) - 1)
    # The GLOBE mask stores True for ocean.
    return bool((bits[row, col >> 3] >> (7 - (col & 7))) & 1)
