# Olist Analytics

A dbt project that models the [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) combining with the [Marketing Funnel Dataset by Olist](https://www.kaggle.com/datasets/olistbr/marketing-funnel-olist) on Snowflake. The pipeline transforms raw transactional data into analytics-ready fact and dimension tables covering customers, orders, sellers, products, and marketing.

## Tech Stack

- **dbt** 1.11 + **dbt-utils** 1.3.3
- **Snowflake**
- **GitHub Actions** for CI/CD

## Architecture

Three-layer medallion architecture, all sourced from `olist_raw.public`.

```
olist_raw.public  (source)
      │
      ▼
   Bronze          views   stg_olist__*        rename + light cleaning
      │
      ▼
   Silver          views   int_<domain>__*     joins, enrichment, business logic
      │
      ▼
    Gold           tables  fct_* / dim_*       analytics-ready facts & dims
```

### Gold Layer

| Model | Grain | Description |
|-------|-------|-------------|
| `fct_customers` | customer | Lifetime order metrics, spend, delivery time, customer type |
| `fct_orders` | order | Payment reconciliation, delivery performance, review score |
| `fct_seller_performance` | seller | GMV, order count, lead acquisition channel |
| `fct_marketing_funnel` | lead | Conversion flag, days to close |
| `fct_customer_churn_features` | customer | ML-ready churn feature table (Python model) |
| `dim_customers` | customer | Identity, location, coordinates |
| `dim_products` | product | Attributes + English category name |
| `dim_sellers` | seller | Location + lead attributes |

## Setup

### Prerequisites

- Python 3.11+
- A Snowflake account with databases `olist_raw` (source), `olist_analytics_dev`, and `olist_analytics_prod`

### Installation

```bash
pip install -r requirements.txt
dbt deps
```

### Profiles

Add the `olist_analytics` profile to `~/.dbt/profiles.yml`:

```yaml
olist_analytics:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: "{{ env_var('SNOWFLAKE_ACCOUNT') }}"
      user: "{{ env_var('SNOWFLAKE_USER') }}"
      password: "{{ env_var('SNOWFLAKE_PASSWORD') }}"
      role: ACCOUNTADMIN
      warehouse: transforming
      database: olist_analytics_dev
      schema: dev_dbt
      threads: 4
```

Set the required environment variables before running:

```bash
export SNOWFLAKE_ACCOUNT=your_account
export SNOWFLAKE_USER=your_user
export SNOWFLAKE_PASSWORD=your_password
```

### Running the project

```bash
dbt seed          # load reference data (product category translations)
dbt snapshot      # capture order status history
dbt build         # run all models + tests
```

## Development

```bash
# build and test a single layer
dbt build --select silver

# build a model and all downstream dependents
dbt build --select fct_customers+

# run only singular tests
dbt test --select test_type:singular
```

## Testing

The project has two types of tests:

- **Schema tests** (YAML) — `not_null`, `unique`, `accepted_values`, `dbt_utils.accepted_range` applied at column level. Known source data issues are downgraded to `severity: warn`.
- **Singular tests** (`tests/`) — custom SQL assertions for cross-model consistency and temporal logic (e.g. delivery timestamps after order date, customer counts matching between silver and gold).

## CI/CD

Two GitHub Actions workflows:

| Workflow | Trigger | What it does |
|----------|---------|--------------|
| `ci.yml` | Pull request to `main` | Slim CI — builds only changed models and their downstream dependents (`state:modified+`) against `olist_analytics_dev.ci_dbt` |
| `cd.yml` | Push to `main` | Full production build (seed → snapshot → build) against `olist_analytics_prod` |

Required GitHub repository secrets: `SNOWFLAKE_ACCOUNT`, `SNOWFLAKE_USER`, `SNOWFLAKE_PASSWORD`.

## Known Data Issues

| Issue | Scale | Handling |
|-------|-------|----------|
| Delivery timestamps (`delivered_carrier_at`, `delivered_customer_at`) precede `order_date` | 166 orders | Nulled out in `stg_olist__orders` |
| `review_id` is not unique — same ID appears across multiple orders | 789 duplicates | `unique` test removed; `fct_orders` deduplicates by `order_id` |
| One order per `customer_id` — a customer placing N orders gets N distinct `customer_id` values | By design | `customer_unique_id` is used as the stable customer identifier throughout |
| One closed deal record has a negative `days_to_close` (deal date precedes lead creation date) | 1 record | Range test downgraded to `severity: warn` in `fct_marketing_funnel` |
| Some delivered orders have null delivery timestamps in the source | ~10 records | `not_null` tests on delivery columns downgraded to `severity: warn` in `int_orders__delivery_performance` |

## Data Sources

Raw tables in `olist_raw.public`:

| Table | Description |
|-------|-------------|
| `orders` | Order header with status and timestamps |
| `order_items` | Line items per order |
| `customers` | Customer per-order identity and location |
| `products` | Product catalogue with dimensions |
| `sellers` | Seller identity and location |
| `payments` | Payment method and installment details |
| `reviews` | Customer review scores and text |
| `geolocation` | Lat/lon coordinates per zip code prefix |
| `marketing_qualified_leads` | Inbound leads from marketing channels |
| `closed_deals` | Leads that converted to seller accounts |
