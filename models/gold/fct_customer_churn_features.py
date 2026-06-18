import pandas as pd


def model(dbt, session):
    dbt.config(
        materialized="table",
        packages=["pandas"],
    )

    df = dbt.ref("fct_customers").to_pandas()

    df["LAST_ORDER_DATE"] = pd.to_datetime(df["LAST_ORDER_DATE"])
    df["FIRST_ORDER_DATE"] = pd.to_datetime(df["FIRST_ORDER_DATE"])

    # use the latest order date in the dataset as the reference point so
    # recency features are meaningful for historical data
    reference_date = df["LAST_ORDER_DATE"].max()

    df["DAYS_SINCE_LAST_ORDER"] = (reference_date - df["LAST_ORDER_DATE"]).dt.days

    df["DAYS_ACTIVE"] = (df["LAST_ORDER_DATE"] - df["FIRST_ORDER_DATE"]).dt.days

    # orders per 30-day period over the customer's active window;
    # null for single-order customers (no active window to measure)
    df["ORDER_VELOCITY_30D"] = df.apply(
        lambda r: (r["TOTAL_ORDERS"] / r["DAYS_ACTIVE"]) * 30
        if r["DAYS_ACTIVE"] > 0
        else None,
        axis=1,
    )

    df["SPEND_PER_ORDER"] = df["TOTAL_CUSTOMER_SPEND"] / df["TOTAL_ORDERS"]

    # spend quartile buckets (1 = lowest, 4 = highest)
    df["SPEND_QUARTILE"] = pd.qcut(
        df["TOTAL_CUSTOMER_SPEND"].rank(method="first"),
        q=4,
        labels=[1, 2, 3, 4],
    ).astype("Int64")

    # churn label: no order in the 6 months prior to the reference date
    df["IS_CHURNED"] = df["DAYS_SINCE_LAST_ORDER"] > 180

    feature_cols = [
        "CUSTOMER_UNIQUE_ID",
        "DAYS_SINCE_LAST_ORDER",
        "DAYS_ACTIVE",
        "TOTAL_ORDERS",
        "TOTAL_CUSTOMER_SPEND",
        "SPEND_PER_ORDER",
        "SPEND_QUARTILE",
        "AVG_DAYS_BETWEEN_ORDERS",
        "ORDER_VELOCITY_30D",
        "AVG_DELIVERY_TIME",
        "IS_CHURNED",
    ]

    return df[feature_cols]
