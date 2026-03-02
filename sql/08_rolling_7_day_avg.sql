/*
Purpose: Rolling 7-day request average
Business Question: Short-term demand volatility
*/

with daily as (
    select
        d.date,
        count(*) as requests
    from dw.fact_311_requests f
    join dw.dim_date d
        on f.created_date_key = d.date_key
    group by d.date
)

select
    date,
    requests,
    avg(requests) over (
        order by date
        rows between 6 preceding and current row
    ) as rolling_7_day_avg
from daily
order by date;