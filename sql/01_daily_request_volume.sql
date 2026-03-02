/*
Purpose: Calculate daily 311 request volume
Business Question: How many service requests are submitted daily?
*/

select
    d.date,
    count(*) as total_requests
from dw.fact_311_requests f
join dw.dim_date d
    on f.created_date_key = d.date_key
group by d.date
order by d.date;