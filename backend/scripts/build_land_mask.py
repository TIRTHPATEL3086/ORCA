"""Build ORCA's regional land/water mask from the global-land-mask package.

global_land_mask unpacks a 933 MB world grid on import, which exceeds the
memory of small cloud instances. ORCA only needs the Indian Ocean, so this
script cuts that window out once and stores it bit-packed (a few MB in RAM).

Run from backend/:  python -m scripts.build_land_mask
"""

from pathlib import Path

import numpy as np
from global_land_mask import globe

from app.services.land_mask import LAT_MAX, LAT_MIN, LON_MAX, LON_MIN, MASK_PATH


def main() -> None:
    lat_axis = globe._lat
    lon_axis = globe._lon

    rows = globe.lat_to_index(np.array([LAT_MAX, LAT_MIN], dtype=float))
    cols = globe.lon_to_index(np.array([LON_MIN, LON_MAX], dtype=float))
    r0, r1 = int(rows.min()), int(rows.max()) + 1
    c0, c1 = int(cols.min()), int(cols.max()) + 1

    window = globe._mask[r0:r1, c0:c1]

    Path(MASK_PATH).parent.mkdir(parents=True, exist_ok=True)
    np.savez_compressed(
        MASK_PATH,
        mask_bits=np.packbits(window, axis=1),
        width=np.int64(window.shape[1]),
        row_offset=np.int64(r0),
        col_offset=np.int64(c0),
        lat0=lat_axis[0],
        dlat=lat_axis[1] - lat_axis[0],
        lat_min=lat_axis.min(),
        lat_max=lat_axis.max(),
        lon0=lon_axis[0],
        dlon=lon_axis[1] - lon_axis[0],
        lon_min=lon_axis.min(),
        lon_max=lon_axis.max(),
    )
    print(f"Saved {window.shape} window to {MASK_PATH}")


if __name__ == "__main__":
    main()
