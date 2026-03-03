# Data Dictionary  
NYC 311 Service Quality & Operational Performance Dashboard

This document describes the data model (PostgreSQL star schema), including table purposes, column definitions, and key data-quality rules applied during modeling.

---

## 1. Data Model Overview

### Schemas
- `stg` — raw staging tables and cleaned staging view
- `dw` — dimensional warehouse (star schema)

### Star Schema Tables (Warehouse)
**Fact Table**
- `dw.fact_311_requests`

**Dimension Tables**
- `dw.dim_date`
- `dw.dim_agency`
- `dw.dim_complaint_type`
- `dw.dim_borough`

---

## 2. Staging Layer

### 2.1 `stg.stg_311_raw`
**Purpose:**  
Raw landing table loaded from CSV/API pull. Minimal transformation is applied here.

| Column | Type | Description |
|-------|------|-------------|
| unique_key | bigint | Unique request identifier from NYC 311 dataset |
| created_date | timestamp | Timestamp when request was created |
| closed_date | timestamp | Timestamp when request was closed (nullable) |
| agency | text | Agency responsible for handling request |
| complaint_type | text | Complaint category |
| borough | text | Borough string label (may be null or "UNSPECIFIED") |
| status | text | Raw status label from source (may be inconsistent) |

---

### 2.2 `stg.v_311_clean` (View)
**Purpose:**  
Cleaned staging view used to standardize and filter the raw data before warehouse loading.

**Cleaning Rules Applied**
- Trim whitespace for `agency`, `complaint_type`, `status`
- Normalize borough to uppercase
- Filter out records with missing `unique_key` or `created_date`
- Convert blank strings to NULL using `NULLIF(trim(col), '')`

| Column | Type | Description |
|-------|------|-------------|
| request_id | bigint | Cleaned request identifier (from unique_key) |
| created_date | timestamp | Request created timestamp |
| closed_date | timestamp | Request closed timestamp (nullable) |
| agency | text | Cleaned agency name (nullable if missing) |
| complaint_type | text | Cleaned complaint type (nullable if missing) |
| borough | text | Upper-cased borough label |
| status | text | Cleaned raw status |

---

## 3. Warehouse Dimensions

### 3.1 `dw.dim_date`
**Purpose:**  
Calendar dimension for filtering, grouping, and time-series analysis.

| Column | Type | Description |
|-------|------|-------------|
| date_key | int | Surrogate date key in format YYYYMMDD (PK) |
| date | date | Actual date value |
| year | int | Calendar year |
| quarter | int | Calendar quarter (1–4) |
| month_num | int | Month number (1–12) |
| month_name | text | Abbreviated month name (e.g., Jan, Feb) |
| week_of_year | int | ISO week-of-year number |
| day_name | text | Abbreviated day name (e.g., Mon, Tue) |
| is_weekend | boolean | True if Saturday/Sunday |

**Date Range Logic**
- Built from minimum of created/closed dates through maximum of created/closed dates to ensure referential integrity with both created and closed date keys.

---

### 3.2 `dw.dim_agency`
**Purpose:**  
Agency lookup dimension.

| Column | Type | Description |
|-------|------|-------------|
| agency_id | serial | Surrogate primary key |
| agency_name | text | Agency name (unique) |

---

### 3.3 `dw.dim_complaint_type`
**Purpose:**  
Complaint type lookup dimension.

| Column | Type | Description |
|-------|------|-------------|
| complaint_type_id | serial | Surrogate primary key |
| complaint_type | text | Complaint type label (unique) |

---

### 3.4 `dw.dim_borough`
**Purpose:**  
Borough lookup dimension.

| Column | Type | Description |
|-------|------|-------------|
| borough_id | serial | Surrogate primary key |
| borough_name | text | Borough label (unique) |

**Common Values**
- BRONX, BROOKLYN, MANHATTAN, QUEENS, STATEN ISLAND, UNSPECIFIED

> Note: "UNSPECIFIED" is treated as a data-quality bucket and may be excluded in certain analyses.

---

## 4. Warehouse Fact Table

### 4.1 `dw.fact_311_requests`
**Purpose:**  
Central fact table at the request level. Stores all core operational fields and derived metrics.

| Column | Type | Description |
|-------|------|-------------|
| request_id | bigint | Request identifier (PK) |
| created_date_key | int | FK to `dw.dim_date(date_key)` (created date) |
| closed_date_key | int | FK to `dw.dim_date(date_key)` (closed date, nullable) |
| agency_id | int | FK to `dw.dim_agency(agency_id)` |
| complaint_type_id | int | FK to `dw.dim_complaint_type(complaint_type_id)` |
| borough_id | int | FK to `dw.dim_borough(borough_id)` |
| status | text | Derived status: `OPEN` if closed_ts null, else `CLOSED` |
| created_ts | timestamp | Raw created timestamp |
| closed_ts | timestamp | Raw closed timestamp (nullable) |
| resolution_time_hours | numeric(10,2) | Derived: hours between closed_ts and created_ts (nullable) |
| resolution_time_days | numeric(10,2) | Derived: days between closed_ts and created_ts (nullable) |
| is_closed_within_7d | boolean | True if closed and resolution ≤ 7 days (nullable for open) |
| is_resolution_valid | boolean | Data-quality flag for resolution validity (nullable for open) |
| resolution_time_days_clean | numeric(10,2) | Cleaned resolution (valid closed only), else NULL |

---

## 5. Derived Fields & Data Quality Rules

### 5.1 Status Derivation
- `OPEN` if `closed_ts` is NULL  
- `CLOSED` if `closed_ts` is NOT NULL

### 5.2 Resolution Time Calculation
For closed cases only:
- `resolution_time_hours = (closed_ts - created_ts) in hours`
- `resolution_time_days = (closed_ts - created_ts) in days`

### 5.3 Resolution Validity Rules
Some source records can produce invalid resolution times (e.g., negative durations).

A closed record is considered valid if:
- `closed_ts >= created_ts`
- `resolution_time_days` between 0 and 365 days

Fields:
- `is_resolution_valid = true/false`
- `resolution_time_days_clean = resolution_time_days` if valid else NULL

> Dashboard metrics use `resolution_time_days_clean` to avoid distortion from invalid or extreme values.

### 5.4 SLA Proxy
- `is_closed_within_7d = true` if closed and resolution_time_days ≤ 7  
- Used in SLA compliance KPI: `% Closed Within 7 Days`

---

## 6. Relationships (Power BI / Warehouse)

Primary relationships:
- `fact_311_requests[created_date_key]` → `dim_date[date_key]` (active)
- `fact_311_requests[closed_date_key]` → `dim_date[date_key]` (inactive, optional for “closures over time”)
- `fact_311_requests[agency_id]` → `dim_agency[agency_id]`
- `fact_311_requests[complaint_type_id]` → `dim_complaint_type[complaint_type_id]`
- `fact_311_requests[borough_id]` → `dim_borough[borough_id]`

---

## 7. Notes on Scope

- This model focuses on operational KPIs and performance monitoring.
- Additional granularity (zip code, precinct, community district) is not included in the MVP schema but can be added as extra dimensions.