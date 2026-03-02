/*
Purpose: SLA compliance by agency
Business Question: What % of cases are resolved within 7 days?
*/

select
    a.agency_name,
    round(
        100.0 * avg(case
            when f.is_closed_within_7d then 1
            else 0
        end), 2
    ) as sla_within_7_days_pct
from dw.fact_311_requests f
join dw.dim_agency a
    on f.agency_id = a.agency_id
where f.status = 'CLOSED'
group by a.agency_name
order by sla_within_7_days_pct asc;