import subprocess
import sys
from pathlib import Path


HERE = Path(__file__).resolve().parent


def run(name):
    path = HERE / name

    print("\n" + "=" * 72)
    print(f"RUNNING {name}")
    print("=" * 72)

    subprocess.run(
        [sys.executable, str(path)],
        cwd=str(HERE),
        check=True,
    )


if __name__ == "__main__":
    run("01_prepare_samples.py")
    run("02_enrich_environment.py")
    run("03_train_models.py")
