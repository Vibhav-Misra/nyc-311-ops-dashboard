/*
Purpose: Monthly request volume trend
Business Question: Are there seasonal spikes?
*/

select
    d.year,
    d.month_num,
    d.month_name,
    count(*) as total_requests
from dw.fact_311_requests f
join dw.dim_date d
    on f.created_date_key = d.date_key
group by d.year, d.month_num, d.month_name
order by d.year, d.month_num;