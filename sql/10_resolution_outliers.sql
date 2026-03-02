/*
Purpose: Identify extreme resolution times
Business Question: Detect operational outliers
*/

select
    a.agency_name,
    f.request_id,
    f.resolution_time_days_clean
from dw.fact_311_requests f
join dw.dim_agency a
    on f.agency_id = a.agency_id
where f.resolution_time_days_clean > 60
order by f.resolution_time_days_clean desc;