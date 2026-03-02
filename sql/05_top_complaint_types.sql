/*
Purpose: Identify most frequent complaint types
Business Question: Which complaint categories dominate volume?
*/

select
    c.complaint_type,
    count(*) as total_requests
from dw.fact_311_requests f
join dw.dim_complaint_type c
    on f.complaint_type_id = c.complaint_type_id
group by c.complaint_type
order by total_requests desc
limit 10;