# dbt Learning Project

A comprehensive dbt (data build tool) project demonstrating modern data transformation practices using a medallion architecture pattern on Databricks. This project showcases retail analytics data transformations from raw sources to business-ready datasets.

## 🏗️ Project Architecture

This project implements a **medallion architecture** with three distinct layers:

### Bronze Layer (Raw Data Ingestion)
The bronze layer serves as the foundation, containing raw data directly ingested from source systems with minimal transformation. Models in this layer:
- Preserve the original structure and data types from source systems
- Act as a staging area for all subsequent transformations  
- Include dimension tables (customer, date, product, store) and fact tables (sales, returns)
- Are materialized as **tables** for optimal performance during frequent access

### Silver Layer (Business Logic & Aggregations)
The silver layer applies business logic and creates meaningful aggregations from bronze data. Key features:
- Combines multiple bronze tables through joins to create business-focused views
- Implements calculated fields using custom macros (e.g., calculated gross amounts)
- Creates analytical datasets like sales information aggregated by category and gender
- Materialized as **views** for flexibility and storage efficiency

### Gold Layer (Business-Ready Analytics)
The gold layer delivers production-ready, highly refined datasets for business intelligence and analytics:
- Applies advanced data quality measures including deduplication logic
- Implements slowly changing dimension (SCD) tracking through snapshots
- Provides clean, business-ready datasets for reporting and dashboards
- Uses ROW_NUMBER() window functions for data deduplication

## 📊 Data Model Overview

The project works with a typical retail analytics schema including:
- **Dimensional Data**: Customer demographics, product catalogs, store information, and date dimensions
- **Transactional Data**: Sales transactions and product returns
- **Reference Data**: Lookup tables and business rules stored as seeds

## 🔧 dbt Features Implemented

### Sources
**What are Sources?**
Sources are dbt's way of defining and documenting the raw data tables that exist in your data warehouse before any dbt transformations. Think of them as the entry points where external data enters your dbt ecosystem.

**Why do we implement Sources?**
- **Avoid Hard-coding**: Instead of writing `SELECT * FROM prod.raw_data.customers`, you write `SELECT * FROM {{ source('raw_data', 'customers') }}`, making your code environment-agnostic
- **Data Lineage**: dbt can track how data flows from sources through all your transformations
- **Testing at Source**: You can test raw data quality before any transformations happen
- **Documentation**: Central place to document what each source table contains
- **Freshness Monitoring**: Track when source data was last updated to catch data pipeline issues

**How they help us:**
- **Environment Management**: Automatically adapt to different database/schema names across dev/staging/prod
- **Impact Analysis**: Understand which models break if a source changes
- **Data Quality**: Catch problems at the source before they propagate through your pipeline
- **Team Collaboration**: Everyone knows where data comes from and what it represents

**Implementation in this project:**
```yaml
sources:
  - name: source
    tables:
      - name: fact_sales      # Sales transactions
      - name: dim_customer    # Customer demographics
      - name: dim_product     # Product catalog
```

### Models
**What are Models?**
Models are the heart of dbt - they're SQL files that define how raw data gets transformed into analytics-ready datasets. Each model represents a table or view in your data warehouse and contains the business logic for that transformation.

**Why do we implement Models?**
- **Modularity**: Break complex transformations into manageable, logical steps
- **Reusability**: Models can reference other models, creating a dependency graph
- **Version Control**: SQL transformations become code that can be reviewed, tested, and deployed
- **Incremental Processing**: Handle large datasets efficiently by only processing new/changed data
- **Business Logic Centralization**: All transformation rules live in one place, not scattered across different tools

**How they help us:**
- **Maintainability**: Change business logic in one place and it propagates everywhere
- **Performance Optimization**: Choose the right materialization (table/view/incremental) for each use case
- **Collaboration**: Data analysts and engineers can work together using familiar SQL
- **Data Governance**: Clear ownership and documentation of transformation logic
- **Dependency Management**: dbt automatically builds models in the correct order

**Layer-by-Layer Implementation:**

**Bronze Models** (Raw Data Standardization):
```sql
-- bronze_customer.sql: Simple passthrough with minimal transformation
SELECT * FROM {{ source('source', 'dim_customer') }}
```
- **Purpose**: Standardize naming, data types, and basic structure
- **Materialization**: Tables (for fast access by downstream models)
- **Why**: Creates a consistent foundation regardless of source system changes

**Silver Models** (Business Logic Application):
```sql
-- silver_salesinfo.sql: Complex business transformations
WITH sales AS (
    SELECT 
        sales_id,
        {{ multiply('unit_price', 'quantity') }} AS calculated_gross_amount,
        payment_method
    FROM {{ ref('bronze_sales') }}
), ...
```
- **Purpose**: Apply business rules, create calculated fields, join related data
- **Materialization**: Views (for flexibility and storage efficiency)
- **Why**: Transform data into business-meaningful metrics and KPIs

**Gold Models** (Analytics-Ready Datasets):
```sql
-- source_gold_items.sql: Deduplication and final preparation  
SELECT id, name, category, updated
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY id ORDER BY updated DESC) AS rn
    FROM {{ source('source', 'items') }}
) WHERE rn = 1
```
- **Purpose**: Create final, clean datasets ready for BI tools and reporting
- **Materialization**: Views or tables depending on usage patterns
- **Why**: Ensure data quality and provide stable interfaces for business users

### Macros
**What are Macros?**
Macros are dbt's way of creating reusable, templated SQL code. They're like functions in programming languages but for SQL - they take parameters, execute logic, and return SQL code that gets compiled into your final queries.

**Why do we implement Macros?**
- **DRY Principle**: Don't Repeat Yourself - write complex logic once, use it everywhere
- **Consistency**: Ensure business calculations are applied the same way across all models
- **Maintainability**: Change business logic in one place and it updates everywhere it's used
- **Database Agnostic**: Write logic that works across different SQL dialects (Snowflake, BigQuery, Redshift, etc.)
- **Complex Logic Abstraction**: Hide complicated SQL patterns behind simple, readable function calls

**How they help us:**
- **Code Efficiency**: A 50-line complex calculation becomes a simple `{{ calculate_profit_margin(revenue, costs) }}`
- **Error Reduction**: Centralized logic means fewer copy-paste errors
- **Business Rule Enforcement**: Ensure everyone calculates metrics the same way
- **Testing**: Test business logic once in the macro rather than in every model
- **Documentation**: Self-documenting code that explains business rules

**Real Examples from this project:**

**Business Logic Macro:**
```sql
-- macros/multiply.sql
{% macro multiply(col1, col2) %}
    {{ col1 }} * {{ col2 }}
{% endmacro %}

-- Usage in models:
SELECT {{ multiply('unit_price', 'quantity') }} AS total_amount
```
- **Purpose**: Standardize multiplication calculations across all models
- **Benefit**: If business rules change (e.g., add rounding), update once in the macro
- **Why**: Even simple operations benefit from standardization and consistency

**Environment Configuration Macro:**
```sql
-- macros/generate_schema.sql: Custom schema naming for different environments
{% macro generate_schema_name(custom_schema_name, node) %}
    {%- if custom_schema_name is none -%}
        {{ target.schema }}  -- Use default in dev
    {%- else -%}
        {{ custom_schema_name | trim }}  -- Use custom in prod
    {%- endif -%}
{% endmacro %}
```
- **Purpose**: Control where models get created in different environments
- **Benefit**: Dev models go to personal schemas, prod models go to shared schemas
- **Why**: Prevents developers from accidentally overwriting production data

**Advanced Macro Capabilities:**
- **Conditional Logic**: Generate different SQL based on runtime variables
- **Loop Constructs**: Dynamically create SQL for multiple similar operations
- **String Manipulation**: Clean and standardize data formats
- **Cross-Database Compatibility**: Abstract database-specific syntax differences

### Seeds
**What are Seeds?**
Seeds are CSV files stored directly in your dbt project that get loaded as tables in your data warehouse. They're perfect for small, static datasets that change infrequently but are essential for your transformations.

**Why do we implement Seeds?**
- **Version Control**: Reference data becomes part of your codebase and follows the same deployment process
- **Reproducibility**: Anyone can clone your project and get the exact same reference data
- **Environment Consistency**: Ensure lookup tables are identical across dev, staging, and production
- **Change Tracking**: Git history shows exactly when and how reference data changed
- **Deployment Simplicity**: No need for separate ETL processes for small static datasets

**How they help us:**
- **Data Governance**: Reference data changes go through the same review process as code changes
- **Environment Management**: Automatically deploy reference data to any environment
- **Collaboration**: Team members can propose changes to business rules via pull requests
- **Audit Trail**: Complete history of how business rules and mappings have evolved
- **Dependency Management**: Models that use seeds automatically rebuild when seed data changes

**Implementation in this project:**
```csv
-- seeds/lookup.csv
product_id,product_category
101,Electronics
102,Fashion  
103,Home & Garden
```

**Usage in Models:**
```sql
-- Reference seed data in any model
SELECT 
    sales.product_id,
    lookup.product_category,
    SUM(sales.amount) as total_sales
FROM {{ ref('bronze_sales') }} sales
JOIN {{ ref('lookup') }} lookup 
    ON sales.product_id = lookup.product_id
```

**Best Practices for Seeds:**
- **Size Limit**: Keep seeds under 1MB (use sources for larger reference data)
- **Update Frequency**: Only use for data that changes rarely (quarterly/yearly)
- **Business Rules**: Perfect for tax rates, category mappings, business hierarchies
- **Configuration Data**: Feature flags, operational parameters, calculation constants

**Seeds vs. Sources comparison:**
- **Seeds**: Small, version-controlled, deployed with code
- **Sources**: Large, externally managed, referenced from data warehouse
- **Use Seeds for**: Business rules, lookup tables, small reference datasets  
- **Use Sources for**: Transactional data, large dimensions, frequently updated data

### Snapshots
**What are Snapshots?**
Snapshots are dbt's implementation of Slowly Changing Dimensions (SCD Type 2), which capture and preserve the historical changes of your data over time. They create a full audit trail showing not just the current state of records, but how they looked at any point in the past.

**Why do we implement Snapshots?**
- **Historical Analysis**: Answer questions like "What was our customer base last quarter?" or "How has product categorization changed?"
- **Regulatory Compliance**: Maintain audit trails required for financial reporting, GDPR, or industry regulations
- **Data Quality Debugging**: When something looks wrong today, trace back to see when it changed
- **Trend Analysis**: Understand how business entities evolve over time
- **Point-in-Time Recovery**: Restore data to any previous state if needed

**How they help us:**
- **Business Intelligence**: Enable time-series reporting and historical trend analysis
- **Data Governance**: Provide complete audit trails for compliance and debugging
- **Decision Making**: Base decisions on historical patterns, not just current snapshots
- **Error Recovery**: Roll back to previous good states when data issues are discovered
- **Performance**: Pre-calculated historical views are faster than complex temporal queries

**Implementation Strategies:**

**Timestamp Strategy** (used in this project):
```yaml
# snapshots/gold_items.yml
snapshots:
  - name: gold_items
    relation: ref('source_gold_items')
    config:
      unique_key: id
      strategy: timestamp
      updated_at: updated
      dbt_valid_to_current: "to_date('9999-12-31')"
```

**How it works:**
1. **First Run**: Creates initial snapshot with all current records
2. **Subsequent Runs**: Compares `updated_at` field to detect changes
3. **Change Detection**: When a record's `updated_at` changes, dbt:
   - Sets `dbt_valid_to` on the old record (marks when it became outdated)
   - Inserts new version with `dbt_valid_from` (marks when new version became active)
4. **Current Records**: Have `dbt_valid_to = '9999-12-31'` indicating they're still active

**Check Strategy** (alternative approach):
- Compares all column values to detect changes
- Use when you don't have reliable timestamp fields
- More comprehensive but slower performance

**Real-world Example:**
```sql
-- Query: "Show me all customers and their categories as they existed on 2024-01-15"
SELECT 
    customer_id,
    category,
    dbt_valid_from,
    dbt_valid_to
FROM {{ ref('customer_snapshot') }}
WHERE '2024-01-15' BETWEEN dbt_valid_from AND dbt_valid_to
```

**Business Value Examples:**
- **Customer Journey Analysis**: Track how customer segments change over time
- **Product Evolution**: See how product categorizations and prices evolve
- **Regulatory Reporting**: Provide historical data for audits and compliance
- **A/B Testing**: Analyze long-term effects of business changes
- **Data Quality Monitoring**: Identify when and how data corruption occurred

**Performance Considerations:**
- **Storage Growth**: Snapshots grow over time as they preserve all historical versions
- **Query Patterns**: Optimize for time-based filtering using `dbt_valid_from/to` columns
- **Retention Policies**: Consider archiving very old snapshot data based on business needs

### Tests
**What are Tests?**
Tests are dbt's data quality framework that automatically validate your data during the build process. They act as guardrails, catching data issues before they reach business users and ensuring your transformations produce reliable, trustworthy results.

**Why do we implement Tests?**
- **Data Quality Assurance**: Prevent bad data from propagating through your pipeline
- **Early Error Detection**: Catch problems during development, not in production
- **Business Rule Enforcement**: Ensure data meets business expectations and constraints
- **Regression Prevention**: Detect when changes break existing assumptions
- **Trust Building**: Give stakeholders confidence in data accuracy and reliability

**How they help us:**
- **Automated Validation**: No manual data checking required - tests run automatically
- **Continuous Monitoring**: Every dbt run validates data quality across all models
- **Fast Feedback**: Developers know immediately when their changes cause data issues
- **Documentation**: Tests serve as executable documentation of business rules
- **CI/CD Integration**: Prevent deployment of models that fail data quality checks

**Types of Tests Implemented:**

**1. Built-in Generic Tests:**
```yaml
# models/bronze/properties.yml
models:
  - name: bronze_sales
    columns:
      - name: sales_id
        data_tests:
          - unique        # Every sales_id must be unique
          - not_null      # No missing sales_id values
      - name: store_name
        data_tests:
          - accepted_values:
              values: ['MegaMart Manhattan', 'MegaMart Brooklyn', 'MegaMart Austin']
```

**Purpose**: Validate fundamental data assumptions
- **unique**: Ensures no duplicate records where they shouldn't exist
- **not_null**: Catches missing critical data that would break joins or calculations
- **accepted_values**: Validates that categorical data contains only expected values
- **relationships**: Ensures referential integrity between related tables

**2. Custom Generic Tests:**
```sql
-- tests/generic/generic_non_negative.sql
{% test generic_non_negative(model, column_name) %}
SELECT *
FROM {{ model }}
WHERE {{ column_name }} < 0
{% endtest %}

-- Usage in properties.yml:
- name: gross_amount
  data_tests:
    - generic_non_negative
```

**Purpose**: Create reusable business rule validation
- **Reusability**: Write once, apply to any model and column
- **Business Logic**: Encode domain-specific rules (e.g., amounts can't be negative)
- **Parameterization**: Flexible tests that adapt to different columns and thresholds
- **Consistency**: Ensure the same business rules apply everywhere

**3. Singular Tests:**
```sql
-- tests/non_negative_test.sql
SELECT *
FROM {{ ref('bronze_sales') }}
WHERE gross_amount < 0 AND net_amount < 0
```

**Purpose**: Test complex, model-specific business logic
- **Complex Logic**: Multi-column validations and business rule combinations
- **Model-Specific**: Tests that only apply to specific models or scenarios
- **Custom Queries**: Full SQL flexibility for complex validation scenarios

**Test Configuration and Severity:**
```yaml
data_tests:
  - accepted_values:
      values: ['MegaMart Manhattan', 'MegaMart Brooklyn']
      config:
        severity: warn  # Don't fail build, just warn
```

**Severity Levels:**
- **error** (default): Fails the dbt run if test fails
- **warn**: Logs warning but continues execution
- **Use Cases**: 
  - **error**: Critical data quality issues that must be fixed
  - **warn**: Data quality concerns that should be monitored but don't block deployment

**Test Execution Workflow:**
1. **Development**: Run `dbt test` to validate your changes
2. **CI/CD Pipeline**: Automated test execution before deployment
3. **Production**: Regular test runs to monitor ongoing data quality
4. **Alerting**: Integration with monitoring tools for test failure notifications

**Business Impact Examples:**
- **Revenue Accuracy**: Tests ensure sales amounts are never negative
- **Customer Data Quality**: Tests verify customer records have required fields
- **Referential Integrity**: Tests ensure all sales reference valid customers and products
- **Business Rules**: Tests validate that discount percentages stay within allowed ranges
- **Operational Monitoring**: Tests catch upstream data source issues quickly

### Analyses
**What are Analyses?**
Analyses are SQL files in dbt that compile but don't execute, designed for ad-hoc queries, data exploration, and investigative work. They bridge the gap between formal model development and quick data analysis, allowing you to leverage dbt's compilation features for one-off queries.

**Why do we implement Analyses?**
- **Exploratory Data Analysis**: Investigate data patterns without creating permanent tables
- **Documentation**: Preserve important queries that explain business insights or data issues
- **Knowledge Sharing**: Share complex queries with team members in a standardized format
- **Development Sandbox**: Test query logic before converting to formal models
- **Business Intelligence**: Create reusable analytical queries for stakeholder requests

**How they help us:**
- **dbt Ecosystem Integration**: Use `ref()`, `source()`, macros, and variables in exploratory queries
- **Version Control**: Track analytical queries alongside your data models
- **Collaboration**: Share analysis approaches and findings with your team
- **Rapid Prototyping**: Quickly test ideas without the overhead of creating full models
- **Documentation**: Preserve the analytical thinking behind business insights

**Implementation Examples from this project:**

**Basic Data Exploration:**
```sql
-- analyses/explore_1.sql
SELECT * 
FROM {{ ref('lookup') }}
```
- **Purpose**: Quick examination of seed data structure and contents
- **Use Case**: Understanding reference data before building complex transformations
- **Benefit**: Uses dbt's `ref()` function, so query works across all environments

**Advanced Analytical Queries:**
```sql
-- analyses/jinja_exploration.sql
{% set payment_methods = ['credit_card', 'cash', 'debit_card'] %}

SELECT 
    payment_method,
    {% for method in payment_methods %}
    SUM(CASE WHEN payment_method = '{{ method }}' THEN gross_amount ELSE 0 END) AS {{ method }}_total
    {%- if not loop.last %},{% endif %}
    {% endfor %}
FROM {{ ref('bronze_sales') }}
GROUP BY payment_method
```
- **Purpose**: Dynamic SQL generation for analytical reporting
- **Use Case**: Exploring data patterns across multiple categories
- **Benefit**: Leverages Jinja templating for flexible, reusable analysis

**Business Intelligence Queries:**
```sql
-- analyses/customer_segmentation.sql
WITH customer_metrics AS (
    SELECT 
        customer_sk,
        COUNT(*) as purchase_count,
        SUM(gross_amount) as total_spent,
        AVG(gross_amount) as avg_order_value,
        MAX(sale_date) as last_purchase_date
    FROM {{ ref('silver_salesinfo') }}
    GROUP BY customer_sk
)
SELECT 
    CASE 
        WHEN total_spent > 1000 THEN 'High Value'
        WHEN total_spent > 500 THEN 'Medium Value'  
        ELSE 'Low Value'
    END as customer_segment,
    COUNT(*) as customer_count,
    AVG(total_spent) as avg_customer_value
FROM customer_metrics
GROUP BY customer_segment
```
- **Purpose**: Ad-hoc customer segmentation analysis
- **Use Case**: Business stakeholder request for customer insights
- **Benefit**: Complex analytical logic without creating permanent tables

**Workflow Integration:**

**Development Process:**
1. **Start with Analysis**: Write exploratory queries in `analyses/` folder
2. **Iterate and Refine**: Test different approaches and business logic
3. **Promote to Model**: Convert successful analysis to formal model when needed
4. **Preserve Knowledge**: Keep analysis files as documentation of analytical thinking

**Compilation and Usage:**
```bash
# Compile analyses (but don't execute)
dbt compile --select analyses/

# Find compiled SQL in target/compiled/project_name/analyses/
# Copy and run in your SQL editor or BI tool
```

**Team Collaboration Benefits:**
- **Analytical Methods**: Share complex analytical approaches across the team
- **Business Logic Documentation**: Preserve the reasoning behind specific calculations
- **Stakeholder Communication**: Provide queries that answer specific business questions
- **Training Resource**: New team members can learn by studying existing analyses

**When to Use Analyses vs. Models:**
- **Use Analyses for**:
  - One-time investigations and data exploration
  - Answering specific stakeholder questions
  - Testing complex logic before model development
  - Documenting analytical approaches and findings

- **Use Models for**:
  - Recurring transformations needed by multiple downstream uses
  - Data that needs to be materialized for performance
  - Core business logic that forms part of your data pipeline
  - Tables/views that will be consumed by BI tools or other applications

## 🚀 Getting Started

### Prerequisites
- dbt Core installed
- Access to a Databricks workspace
- Python environment with required dependencies

### Project Structure
```
dbt_learn/
├── models/
│   ├── bronze/          # Raw data ingestion layer
│   ├── silver/          # Business logic transformations  
│   ├── gold/            # Analytics-ready datasets
│   └── source/          # Source definitions
├── macros/              # Reusable SQL functions
├── seeds/               # Static reference data (CSV files)
├── snapshots/           # Historical data tracking
├── tests/               # Data quality validations
├── analyses/            # Ad-hoc queries and exploration
└── dbt_project.yml      # Project configuration
```

### Configuration
The project is configured to work with Databricks using:
- **Development Environment**: For building and testing transformations
- **Production Environment**: For deployed, production-ready data pipelines
- **Schema Separation**: Different schemas for bronze, silver, and gold layers
- **Materialization Strategy**: Tables for bronze (performance), views for silver/gold (flexibility)

## 📈 Key Benefits

- **Scalability**: Medallion architecture supports growing data volumes and complexity
- **Data Quality**: Comprehensive testing ensures reliable, trustworthy data
- **Maintainability**: Modular design and reusable macros reduce code duplication  
- **Collaboration**: Version-controlled SQL enables team collaboration and code reviews
- **Documentation**: Self-documenting code with clear lineage and dependencies
- **Environment Management**: Separate dev/prod environments for safe development practices

## 🔄 Data Lineage

The project demonstrates clear data lineage from source systems through each transformation layer:
1. **Raw Sources** → **Bronze Layer** (ingestion)
2. **Bronze Layer** → **Silver Layer** (business logic)
3. **Silver Layer** → **Gold Layer** (analytics preparation)
4. **Gold Layer** → **Snapshots** (historical tracking)

This lineage is automatically tracked by dbt and can be visualized using `dbt docs generate` and `dbt docs serve`.

### Resources:
- Learn more about dbt [in the docs](https://docs.getdbt.com/docs/introduction)
- Check out [Discourse](https://discourse.getdbt.com/) for commonly asked questions and answers
- Join the [chat](https://community.getdbt.com/) on Slack for live discussions and support
- Find [dbt events](https://events.getdbt.com) near you
- Check out [the blog](https://blog.getdbt.com/) for the latest news on dbt's development and best practices

---

*This project serves as a comprehensive learning resource for dbt best practices, demonstrating real-world data transformation patterns in a retail analytics context.*