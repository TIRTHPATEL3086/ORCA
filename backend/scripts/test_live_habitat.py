from __future__ import annotations

import argparse

from app.services.live_habitat_service import (
    evaluate_live_habitat,
)


def main():
    parser = argparse.ArgumentParser()

    parser.add_argument(
        "--lat",
        type=float,
        default=11.91313333,
    )
    parser.add_argument(
        "--lon",
        type=float,
        default=80.14531667,
    )

    args = parser.parse_args()

    result = evaluate_live_habitat(
        args.lat,
        args.lon,
    )

    print(
        result.model_dump_json(
            indent=2
        )
    )


if __name__ == "__main__":
    main()
