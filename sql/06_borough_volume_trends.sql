/*
Purpose: Compare request volume across boroughs
Business Question: Which boroughs generate the highest demand?
*/

select
    b.borough_name,
    count(*) as total_requests
from dw.fact_311_requests f
join dw.dim_borough b
    on f.borough_id = b.borough_id
group by b.borough_name
order by total_requests desc;