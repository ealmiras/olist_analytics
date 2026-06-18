# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A dbt project (`olist_analytics`) modelling data from the Brazilian e-commerce platform Olist, running on Snowflake. Uses a medallion architecture (bronze → silver → gold) with seeds, snapshots, singular tests, a Python model, and GitHub Actions CI/CD.

## Common Commands

```bash
# Run all models
dbt run

# Run a specific layer
dbt run --select bronze
dbt run --select silver
dbt run --select gold

# Run a specific model and its downstream dependents
dbt run --select fct_customers+

# Build (run + test) a layer
dbt build --select silver

# Run only singular tests
dbt test --select test_type:singular

# Run only schema tests
dbt test --select test_type:generic

# Load seeds
dbt seed

# Run snapshots
dbt snapshot

# Install packages
dbt deps
```

## Architecture

Three-layer medallion architecture sourced from `olist_raw.public`.

**Bronze (`models/bronze/` → schema `bronze`, views)**
Staging models that rename and lightly clean raw source columns. Named `stg_olist__<entity>.sql`. Sources registered in `_src_bronze__sources.yml`. Model tests and docs in `_stg_bronze__models.yml`.

Entities: `orders`, `order_items`, `customers`, `products`, `sellers`, `payments`, `reviews`, `geolocation`, `marketing_leads`, `closed_deals`

Notable: `stg_olist__orders` nulls out delivery timestamps that precede `order_date` (source data quality fix). `stg_olist__products` joins the `product_category_translations` seed to add `product_category_name_english`.

**Silver (`models/silver/` → schema `silver`, views)**
Intermediate models joining and enriching bronze entities. Named `int_<domain>__<description>.sql`. All documented in `_int_silver__models.yml`.

- `int_customers__order_detail` — orders + customers (order grain)
- `int_order_items__enriched` — order items + orders + products + sellers + customers (item grain)
- `int_orders__total_payment` — payment aggregation + reconciliation status per order
- `int_orders__delivery_performance` — delivery time breakdown (delivered orders only)
- `int_sellers__closed_leads` — sellers + closed deals + marketing leads
- `int_reviews__order_enriched` — reviews + orders + customers
- `int_customers__geolocation` — customers + lat/lon from geolocation (zip codes averaged to centroid)
- `int_payments__order_detail` — unaggregated payments + orders (installment grain)
- `int_products__category_metrics` — aggregated metrics per product category

**Gold (`models/gold/` → schema `gold`, tables)**
Fact and dimension tables for analytics. Named `fct_<domain>__<description>.sql` or `dim_<entity>.sql`. All documented in `_fct_gold__models.yml`.

Fact tables:
- `fct_customers` — one row per unique customer with lifetime metrics
- `fct_orders` — one row per order combining payment, delivery, and review
- `fct_seller_performance` — one row per seller with GMV and order metrics
- `fct_marketing_funnel` — one row per lead with conversion flag and days to close
- `fct_customer_churn_features` — Python model; ML feature table built from `fct_customers`

Dimension tables:
- `dim_customers` — one row per `customer_unique_id` with location and coordinates
- `dim_products` — one row per product with all attributes
- `dim_sellers` — one row per seller with location and lead acquisition attributes

## Key Conventions

- Model naming: `<layer_prefix>_<source>__<entity>` (double underscore separates source from entity)
- Source database: `olist_raw`, schema: `public`; registered under source name `olist`
- Active order statuses filter uses the macro `{{ active_order_statuses() }}` — never hardcode the list
- Active statuses: `invoiced`, `delivered`, `approved`, `shipped`
- `dbt_utils.accepted_range` arguments are nested under an `arguments:` key (project convention)
- Snowflake date math: `datediff(day, start, end)` — lowercase `day`
- CTEs follow: source CTEs first → transformation CTEs → `final` → `select * from final`
- Gold models filter to active statuses; silver models generally do not (except delivery performance)

## Macros

- `active_order_statuses()` — returns the active order status tuple for use in `WHERE` clauses

## Seeds

- `seeds/product_category_translations.csv` — maps Portuguese product category names to English; joined in `stg_olist__products`

## Snapshots

- `snapshots/snap_olist__orders.sql` — SCD Type 2 snapshot on the raw orders table using `check` strategy on `order_status` and delivery timestamp columns; writes to `olist_analytics_dev.snapshots`

## Tests

Schema tests (YAML) cover `not_null`, `unique`, `accepted_values`, and `dbt_utils.accepted_range`. Known source data issues are downgraded to `severity: warn` rather than removed.

Singular tests (`tests/`):
- `assert_category_metrics_revenue_matches` — revenue in `int_products__category_metrics` matches `int_order_items__enriched`
- `assert_fct_customers_complete` — no customers lost or invented between silver and gold
- `assert_order_date_before_delivery` — delivery timestamps must be after order placement
- `assert_first_last_order_date_sequential` — `first_order_date` ≤ `last_order_date` in `fct_customers`
- `assert_approval_after_order_date` — approval timestamp must be after order date

## CI/CD

Two GitHub Actions workflows in `.github/workflows/`:

- **`ci.yml`** — triggers on PRs to `main`; runs `dbt build --select state:modified+ --defer --state prod-manifest/` using slim CI against `olist_analytics_dev.ci_dbt`; falls back to full build if no prod manifest exists yet
- **`cd.yml`** — triggers on push to `main`; runs seed → snapshot → full build against `olist_analytics_prod`; uploads `manifest.json` as the `production-manifest` artifact for slim CI

Workflows use a project-level `profiles.yml` (via `--profiles-dir .`) with credentials injected from GitHub repository secrets: `SNOWFLAKE_ACCOUNT`, `SNOWFLAKE_USER`, `SNOWFLAKE_PASSWORD`.
