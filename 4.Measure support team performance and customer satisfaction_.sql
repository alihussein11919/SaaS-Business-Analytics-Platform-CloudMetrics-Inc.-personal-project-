with dates as (
select
    created_date,
    resolved_date,
    resolution_hours
from
    support_tickets
    )

,cte2 as(
select
    created_date,
    resolved_date,
    datediff(hour,created_date,resolved_date) as                    total_response_time_IN_hours,
    resolution_hours

from
    dates
)

select
    *
from
    cte2
order by total_response_time_IN_hours asc










--------------resolution time trends------------------
select
    date_trunc(month,created_date) AS month,
    count(ticket_id)      AS total_tickets,
    avg(resolution_hours) AS avg_resolution_hours,
    min(resolution_hours) AS min_resolution_hours,
    max(resolution_hours) AS max_resolution_hours
from support_tickets
where resolved_date is not NULL
group by date_trunc(month,created_date) 
order by month;




--------------ticket volume per customer and plan-------------
select
st.customer_id,
p.plan_name,
count(created_date) as ticket_volume
from
support_tickets st

join subscriptions s
on s.customer_id = st.customer_id
join plans p
on p.plan_id = s.plan_id

group by st.customer_id, p.plan_name;






-------------------ticket rate analysis----------------------



with last_resolved as(
select
    customer_id,
    ticket_id,
    created_date,

    lag(resolved_date)over(partition by customer_id order by      created_date) as last_resolve


from support_tickets
)

,ctee as(
select
    *,
    datediff(day,last_resolve,created_date) as                    days_since_last_resolve
from last_resolved
)
,cteee as(
select
*,
case when   days_since_last_resolve is null then 'new'

when        days_since_last_resolve is not null and                      days_since_last_resolve > 0 then 'repeat'

when        days_since_last_resolve is not null and                      days_since_last_resolve = 0 then 'repeat'

end as type

from ctee
)

,type_numbers as(
select
type,

round(
count(type)/(select(count(*))from cteee) * 100,2)
as pct_of_customers

from cteee
group by type
)

select
*
from type_numbers

