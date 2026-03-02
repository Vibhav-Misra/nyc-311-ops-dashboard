/*
Purpose: Evaluate resolution efficiency by agency
Business Question: Which agencies have longest resolution times?
*/

select
    a.agency_name,
    count(*) filter (where f.status = 'CLOSED') as closed_cases,
    round(avg(f.resolution_time_days_clean), 2) as avg_resolution_days,
    round(percentile_cont(0.5)
        within group (order by f.resolution_time_days_clean), 2) as median_resolution_days
from dw.fact_311_requests f
join dw.dim_agency a
    on f.agency_id = a.agency_id
where f.status = 'CLOSED'
    and f.resolution_time_days_clean is not null
group by a.agency_name
order by avg_resolution_days desc;