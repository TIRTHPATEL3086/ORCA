from __future__ import annotations

import json
from pathlib import Path

import joblib
import numpy as np
import pandas as pd
from sklearn.compose import ColumnTransformer
from sklearn.ensemble import HistGradientBoostingClassifier, RandomForestClassifier
from sklearn.impute import SimpleImputer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import (
    average_precision_score,
    balanced_accuracy_score,
    brier_score_loss,
    f1_score,
    precision_score,
    recall_score,
    roc_auc_score,
)
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler

from config import ARTIFACTS, PROCESSED, RANDOM_SEED


FEATURES = [
    "depth_m",
    "bathy_slope_m_per_km",
    "month_sin",
    "month_cos",
    "doy_sin",
    "doy_cos",
    "sst_c",
    "sst_anom_c",
    "sst_error_c",
    "sst_local_range_c",
    "chl_mg_m3",
    "log_chl",
    "chl_local_range",
    "wind_speed_ms",
    "eastward_wind_ms",
    "northward_wind_ms",
]


def metrics(y_true, probability):
    prediction = (
        probability >= 0.5
    ).astype(int)

    return {
        "roc_auc": float(
            roc_auc_score(
                y_true,
                probability,
            )
        ),
        "pr_auc": float(
            average_precision_score(
                y_true,
                probability,
            )
        ),
        "balanced_accuracy": float(
            balanced_accuracy_score(
                y_true,
                prediction,
            )
        ),
        "precision": float(
            precision_score(
                y_true,
                prediction,
                zero_division=0,
            )
        ),
        "recall": float(
            recall_score(
                y_true,
                prediction,
                zero_division=0,
            )
        ),
        "f1": float(
            f1_score(
                y_true,
                prediction,
                zero_division=0,
            )
        ),
        "brier": float(
            brier_score_loss(
                y_true,
                probability,
            )
        ),
    }


def temporal_split(df):
    # Model selection:
    # train = 2011-2014
    # validation = 2015
    # final independent test = 2016-2018
    years = pd.to_datetime(
        df["date"]
    ).dt.year

    train = df[years <= 2014].copy()
    validation = df[years == 2015].copy()
    test = df[years >= 2016].copy()

    if (
        train["label"].nunique() < 2
        or validation["label"].nunique() < 2
        or test["label"].nunique() < 2
    ):
        raise RuntimeError(
            "Temporal split lacks both classes. "
            "Check sample generation."
        )

    return train, validation, test


def build_models():
    median = SimpleImputer(
        strategy="median",
        add_indicator=True,
    )

    logistic = Pipeline(
        [
            ("imputer", median),
            ("scale", StandardScaler()),
            (
                "model",
                LogisticRegression(
                    max_iter=3000,
                    class_weight="balanced",
                    random_state=RANDOM_SEED,
                ),
            ),
        ]
    )

    random_forest = Pipeline(
        [
            (
                "imputer",
                SimpleImputer(
                    strategy="median",
                    add_indicator=True,
                ),
            ),
            (
                "model",
                RandomForestClassifier(
                    n_estimators=500,
                    min_samples_leaf=4,
                    max_features="sqrt",
                    class_weight="balanced_subsample",
                    n_jobs=-1,
                    random_state=RANDOM_SEED,
                ),
            ),
        ]
    )

    histogram_gb = Pipeline(
        [
            (
                "imputer",
                SimpleImputer(
                    strategy="median",
                    add_indicator=True,
                ),
            ),
            (
                "model",
                HistGradientBoostingClassifier(
                    learning_rate=0.05,
                    max_iter=300,
                    max_leaf_nodes=15,
                    min_samples_leaf=10,
                    l2_regularization=1.0,
                    random_state=RANDOM_SEED,
                ),
            ),
        ]
    )

    return {
        "logistic_regression": logistic,
        "random_forest": random_forest,
        "hist_gradient_boosting": histogram_gb,
    }


def main():
    source = PROCESSED / "training_features.csv"

    if not source.exists():
        raise FileNotFoundError(
            "Run 02_enrich_environment.py first."
        )

    df = pd.read_csv(source)

    missing = [
        feature
        for feature in FEATURES
        if feature not in df.columns
    ]

    if missing:
        raise RuntimeError(
            f"Missing features: {missing}"
        )

    # Do not silently train if the central EO features are mostly missing.
    minimum_required = {
        "sst_c": 0.80,
        "chl_mg_m3": 0.50,
        "wind_speed_ms": 0.70,
    }

    for column, minimum in minimum_required.items():
        completeness = df[column].notna().mean()

        if completeness < minimum:
            raise RuntimeError(
                f"{column} completeness is only "
                f"{completeness:.1%}. Required: {minimum:.0%}. "
                "Fix environmental extraction before training."
            )

    train, validation, test = temporal_split(df)

    X_train = train[FEATURES]
    y_train = train["label"].astype(int)

    X_validation = validation[FEATURES]
    y_validation = validation["label"].astype(int)

    X_test = test[FEATURES]
    y_test = test["label"].astype(int)

    models = build_models()
    validation_results = {}

    for name, model in models.items():
        print(f"\nTraining {name} ...")
        model.fit(
            X_train,
            y_train,
        )

        p = model.predict_proba(
            X_validation
        )[:, 1]

        validation_results[name] = metrics(
            y_validation,
            p,
        )

        print(
            json.dumps(
                validation_results[name],
                indent=2,
            )
        )

    # Choose by PR-AUC because presence/background data is not a simple
    # balanced laboratory classification problem.
    winner_name = max(
        validation_results,
        key=lambda name: validation_results[name]["pr_auc"],
    )

    print(
        f"\nSelected by validation PR-AUC: {winner_name}"
    )

    winner = models[winner_name]

    # Refit winner on all pre-2016 data, then evaluate only once on 2016-2018.
    development = pd.concat(
        [train, validation],
        ignore_index=True,
    )

    winner.fit(
        development[FEATURES],
        development["label"].astype(int),
    )

    test_probability = winner.predict_proba(
        X_test
    )[:, 1]

    test_metrics = metrics(
        y_test,
        test_probability,
    )

    ARTIFACTS.mkdir(
        parents=True,
        exist_ok=True,
    )

    model_path = ARTIFACTS / "habitat_opportunity_v1.joblib"
    joblib.dump(
        {
            "model": winner,
            "features": FEATURES,
            "model_name": winner_name,
            "training_window": "2011-2015",
            "test_window": "2016-2018",
            "interpretation": (
                "Presence-background habitat suitability score. "
                "Not an official INCOIS PFZ probability."
            ),
        },
        model_path,
    )

    report = {
        "model_selected": winner_name,
        "validation_metrics": validation_results,
        "independent_temporal_test_metrics": test_metrics,
        "sample_counts": {
            "train_2011_2014": int(len(train)),
            "validation_2015": int(len(validation)),
            "test_2016_2018": int(len(test)),
            "total": int(len(df)),
        },
        "feature_completeness": {
            feature: float(
                df[feature].notna().mean()
            )
            for feature in FEATURES
        },
        "important_interpretation": (
            "These metrics measure discrimination between documented fish "
            "occurrences and controlled background samples. They are not "
            "official PFZ accuracy and should not be described that way."
        ),
    }

    report_path = ARTIFACTS / "habitat_opportunity_v1_metrics.json"
    report_path.write_text(
        json.dumps(
            report,
            indent=2,
        ),
        encoding="utf-8",
    )

    scored = test[
        [
            "sample_id",
            "label",
            "date",
            "latitude",
            "longitude",
            "scientific_name",
        ]
    ].copy()
    scored["habitat_score_0_100"] = (
        test_probability * 100
    )
    scored.to_csv(
        ARTIFACTS / "habitat_opportunity_v1_test_predictions.csv",
        index=False,
    )

    print("\nIndependent temporal test:")
    print(
        json.dumps(
            test_metrics,
            indent=2,
        )
    )
    print(f"\nModel: {model_path}")
    print(f"Metrics: {report_path}")


if __name__ == "__main__":
    main()
