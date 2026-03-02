/*
Purpose: Rank agencies by SLA performance
Business Question: Which agencies are underperforming?
*/

select
    agency_name,
    sla_within_7_days_pct,
    rank() over (
        order by sla_within_7_days_pct asc
    ) as performance_rank
from (
    select
        a.agency_name,
        100.0 * avg(case
            when f.is_closed_within_7d then 1
            else 0
        end) as sla_within_7_days_pct
    from dw.fact_311_requests f
    join dw.dim_agency a
        on f.agency_id = a.agency_id
    where f.status = 'CLOSED'
    group by a.agency_name
) t;