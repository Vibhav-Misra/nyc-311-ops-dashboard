/*
Purpose: True backlog calculation by month (as-of date logic)
Business Question: Is backlog increasing over time?
*/

with month_end as (
    select
        max(date) as month_end_date
    from dw.dim_date
    group by year, month_num
)

select
    m.month_end_date,
    count(*) as open_backlog
from month_end m
join dw.fact_311_requests f
    on f.created_ts::date <= m.month_end_date
    and (
        f.closed_ts is null
        or f.closed_ts::date > m.month_end_date
    )
group by m.month_end_date
order by m.month_end_date;