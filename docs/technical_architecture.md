# Technical Architecture
NYC 311 Service Quality &amp; Operational Performance Dashboard
This document outlines the end-to-end technical design of the NYC 311 analytics pipeline,
including ingestion, transformation, dimensional modeling, and visualization layers.
---
# 1. System Overview
The project follows a structured analytics workflow:
NYC Open Data API
→ CSV Extraction
→ PostgreSQL Staging Layer
→ Cleaned View
→ Dimensional Warehouse (Star Schema)
→ Power BI Semantic Model
→ Executive Dashboard
This architecture mirrors a simplified production analytics pipeline.
---
# 2. Data Source
**Source:** NYC Open Data Portal
Dataset: 311 Service Requests
**Access Method:**
- Socrata API (CSV endpoint)
- Pulled via Python script (`pull_311.py`)
- Date window constrained to recent 24 months
- ~5 million records ingested
**Why API instead of manual CSV?**
- Reproducibility
- Controlled date filtering
- Scripted extraction
- Aligns with real-world ingestion practices
---

# 3. Ingestion Layer
### 3.1 Raw Landing (CSV)
Data pulled via:
```bash
python pull_311.py
```
**The script:**
- Applies date filtering (created_date range)
- Downloads directly from API
- Saves to CSV locally
### 3.2 PostgreSQL Staging Table (stg.stg_311_raw)
The raw CSV is loaded into PostgreSQL using:
- `COPY` command
- No heavy transformations
- Preserves original schema
**Purpose:**
- Maintain raw record fidelity
- Enable auditability
- Separate raw from cleaned logic
---
# 4. Cleaning &amp; Transformation Layer
### 4.1 Cleaned View (stg.v_311_clean)
Instead of modifying raw data, a cleaned view is created.
Cleaning operations include:
- `NULLIF(trim(column), &#39;&#39;)`
- Uppercase borough normalization
- Filtering invalid request IDs
- Standardized status logic
**This approach:**
- Preserves raw data integrity
- Centralizes transformation logic
- Simplifies warehouse loading

---
# 5. Dimensional Modeling (Star Schema)
The warehouse layer (`dw` schema) follows a classic star schema design.
### 5.1 Fact Table
**dw.fact_311_requests**
**Grain:**
- One row per service request
**Contains:**
- Foreign keys to dimensions
- Created &amp; closed timestamps
- Derived metrics (resolution time)
- SLA flag
- Validity flags
**This table supports:**
- Time-series analysis
- Backlog reconstruction
- Efficiency metrics
- Performance ranking
### 5.2 Dimension Tables
**dw.dim_date** Calendar dimension with:
- Date key (YYYYMMDD)
- Year, month, quarter
- Week number
- Weekend flag
**Supports:**
- Time aggregation
- Rolling averages
- MoM comparisons
- As-of-date backlog logic
**dw.dim_agency** Agency lookup table with surrogate key.
**dw.dim_complaint_type** Complaint category lookup.
**dw.dim_borough** Standardized borough dimension including:
- BRONX

- BROOKLYN
- MANHATTAN
- QUEENS
- STATEN ISLAND
- UNSPECIFIED (data-quality bucket)
---
# 6. Derived Metrics &amp; Data Quality Engineering
### 6.1 Resolution Time Calculation
For closed cases:
`resolution_time_days = (closed_ts - created_ts)`
Invalid cases may occur due to:
- Data-entry errors
- Timestamp inconsistencies
To prevent metric distortion:
- `is_resolution_valid` flag introduced
- `resolution_time_days_clean` used in KPIs
- Invalid / extreme values excluded from averages
This ensures statistical robustness.
### 6.2 True Backlog (As-Of-Date Reconstruction)
Backlog at date D is defined as:
`created_date ≤ D`
`AND`
`(closed_date IS NULL OR closed_date &gt; D)`
This allows reconstruction of historical backlog levels rather than simply counting current
open tickets.
**Why this matters:**
- Simple open counts distort historical analysis.
- True backlog enables trend analysis and MoM growth tracking.
**This logic is implemented in:**
- DAX (Power BI)
- SQL (window-based backlog script)
---

# 7. Indexing &amp; Performance Optimization
Indexes added on:
- `created_date_key`
- `agency_id`
- `borough_id`
- `complaint_type_id`
- `status`
**Purpose:**
- Faster aggregations
- Improved join performance
- Scalable time-series analysis
With ~5M rows, indexing ensures acceptable query latency.
---
# 8. Analytical Layer (Power BI)
Power BI connects directly to PostgreSQL warehouse.
**Features implemented:**
- Multi-page dashboard
- Drill-through (Agency Deep Dive)
- Rolling 7-day averages
- MoM backlog growth
- Agency SLA ranking
- Resolution-time bucket distributions
**DAX layer handles:**
- KPI definitions
- Time intelligence
- Backlog reconstruction
- Ranking logic
---
# 9. Architectural Design Decisions
**Why Star Schema?**
- Simplifies BI relationships
- Enables performant aggregations
- Aligns with industry analytics standards

- Recruiter-recognizable modeling pattern
**Why Separate Staging and Warehouse?**
- Preserves raw data
- Makes transformations auditable
- Reflects production ETL best practice
**Why Clean Resolution Logic?**
- Prevents distorted averages
- Protects SLA metrics
- Maintains analytical integrity
---
# 10. Scalability Considerations
This architecture can be extended by:
- Adding ZIP code / community district dimension
- Automating API pull with scheduled job
- Migrating PostgreSQL to cloud (AWS RDS / Azure)
- Publishing Power BI via Power BI Service
The model is compatible with larger-scale civic analytics deployments.
---
# 11. Summary
This project demonstrates:
- Data ingestion via API
- SQL-based data cleaning
- Dimensional modeling (star schema)
- Advanced backlog reconstruction logic
- Performance-optimized warehouse design
- Executive-ready BI development
It bridges analytics engineering and operational analytics, transforming open civic data into
structured decision-support intelligence.