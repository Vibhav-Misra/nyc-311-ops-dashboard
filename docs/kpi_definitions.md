# KPI Definitions
NYC 311 Service Quality &amp; Operational Performance Dashboard
This document formally defines all key performance indicators (KPIs) used in the
dashboard.
---
# 1. Volume Metrics
## 1.1 Total Requests
**Definition:**
Total number of 311 service requests in the selected filter context.
**DAX:**
```DAX
Total Requests = COUNTROWS(&#39;fact_311_requests&#39;)
```
**Business Meaning:**
Represents overall demand on the 311 system.
---
## 1.2 Open Requests
**Definition:**
Number of requests with no recorded closed timestamp.
**DAX:**
```DAX
Open Requests =
CALCULATE(
[Total Requests],
&#39;fact_311_requests&#39;[status] = &quot;OPEN&quot;
)
```
**Business Meaning:**
Current unresolved workload.
---

## 1.3 Closed Requests
**Definition:**
Requests with a valid closed timestamp.
**DAX:**
```DAX
Closed Requests =
CALCULATE(
[Total Requests],
&#39;fact_311_requests&#39;[status] = &quot;CLOSED&quot;
)
```
---
# 2. Efficiency Metrics
## 2.1 Average Resolution Time (Days)
**Definition:**
Average time between request creation and closure, excluding invalid durations.
**Derived Field (SQL):**
```SQL
resolution_time_days_clean
```
**Only valid where:**
* closed_ts &gt;= created_ts
* resolution_time_days between 0 and 365
**DAX:**
```DAX
Avg Resolution Time (Days) =
AVERAGEX(
FILTER(
&#39;fact_311_requests&#39;,
&#39;fact_311_requests&#39;[status] = &quot;CLOSED&quot;
&amp;&amp; NOT(ISBLANK(&#39;fact_311_requests&#39;[resolution_time_days_clean]))
),
&#39;fact_311_requests&#39;[resolution_time_days_clean]

)
```
**Business Meaning:**
Measures average service efficiency.
---
## 2.2 Median Resolution Time (Days)
**Definition:**
Median closure time for valid closed requests.
**DAX:**
```DAX
Median Resolution Time (Days) =
MEDIANX(
FILTER(
&#39;fact_311_requests&#39;,
&#39;fact_311_requests&#39;[status] = &quot;CLOSED&quot;
&amp;&amp; NOT(ISBLANK(&#39;fact_311_requests&#39;[resolution_time_days_clean]))
),
&#39;fact_311_requests&#39;[resolution_time_days_clean]
)
```
**Business Meaning:**
Less sensitive to extreme outliers than the average.
---
# 3. SLA Compliance
## 3.1 % Closed Within 7 Days
**Definition:**
Percentage of closed requests resolved within 7 days.
**Derived Field (SQL):**
```SQL
is_closed_within_7d
```

**DAX:**
```DAX
% Closed Within 7 Days =
DIVIDE(
CALCULATE(
[Closed Requests],
&#39;fact_311_requests&#39;[is_closed_within_7d] = TRUE()
),
[Closed Requests]
)
```
**Business Meaning:**
Proxy for service-level agreement compliance.
---
# 4. Backlog Metrics
## 4.1 Open Backlog (As Of Date)
**Definition:**
True historical backlog reconstruction.
**A request is considered open on date D if:**
* created_date &lt;= D
* AND (closed_date IS NULL OR closed_date &gt; D)
**DAX:**
```DAX
Open Backlog (As Of Date) =
VAR AsOfKey = MAX(&#39;dim_date&#39;[date_key])
RETURN
CALCULATE(
COUNTROWS(&#39;fact_311_requests&#39;),
REMOVEFILTERS(&#39;dim_date&#39;),
&#39;fact_311_requests&#39;[created_date_key] &lt;= AsOfKey,
ISBLANK(&#39;fact_311_requests&#39;[closed_date_key])
|| &#39;fact_311_requests&#39;[closed_date_key] &gt; AsOfKey
)
```
**Business Meaning:**

Represents workload at a specific point in time, not just currently open cases.
---
## 4.2 Backlog Month-over-Month Change %
**Definition:**
Relative change in backlog compared to previous month.
**DAX:**
```DAX
Backlog MoM Change % =
VAR CurrentValue = [Open Backlog (As Of Date)]
VAR PreviousValue =
CALCULATE(
[Open Backlog (As Of Date)],
DATEADD(&#39;dim_date&#39;[date], -1, MONTH)
)
RETURN
DIVIDE(CurrentValue - PreviousValue, PreviousValue)
```
---
# 5. Demand Trend Metrics
## 5.1 Rolling 7-Day Average Requests
**Definition:**
Smoothed short-term volume trend.
**DAX:**
```DAX
Rolling 7D Avg Requests =
DIVIDE(
CALCULATE(
[Total Requests],
DATESINPERIOD(
&#39;dim_date&#39;[date],
MAX(&#39;dim_date&#39;[date]),
-7,
DAY
)

),
7
)
```
---
# 6. Ranking Metrics
## 6.1 Agency SLA Rank
**Definition:**
Ranking of agencies based on SLA compliance (ascending = worst first).
**DAX:**
```DAX
Agency SLA Rank =
RANKX(
ALL(&#39;dim_agency&#39;[agency_name]),
[% Closed Within 7 Days],
,
ASC,
DENSE
)
```
**Business Meaning:**
Identifies underperforming agencies.
---
# Summary
These KPIs collectively measure:
* Demand
* Efficiency
* Compliance
* Backlog risk
* Relative performance
Together, they enable operational performance monitoring and strategic decision support.