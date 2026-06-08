with cte as(
select
customer_id,
datediff(   month,
        min(start_date),
        max(end_date)) as tenure_months

from     finalproject.public.subscriptions
group by customer_id
)

select
count(customer_id),

case when tenure_months < 3 then 'Early'
when tenure_months >= 3 then 'Long Term'
else 'Still active'
end as Churn_tenure

from cte
group by
case when tenure_months < 3 then 'Early'
when tenure_months >= 3 then 'Long Term'
else 'Still active'
end

;
--churn by plan
SELECT
    p.plan_name,
    COUNT(DISTINCT s.customer_id) AS churned_customers
FROM subscriptions s
JOIN plans p
    ON s.plan_id = p.plan_id
WHERE s.end_date IS NOT NULL
GROUP BY p.plan_name
ORDER BY churned_customers DESC;



-- by industry
SELECT
    i.industry_name,
    COUNT(DISTINCT s.customer_id) AS churned_customers
FROM subscriptions s
JOIN customers c
    ON s.customer_id = s.customer_id
JOIN industries i
on i.industry_id = c.industry_id
WHERE s.end_date IS NOT NULL
GROUP BY i.industry_name
ORDER BY churned_customers DESC;

SELECT
    u.reports_generated,
    COUNT(DISTINCT s.customer_id) AS churned_customers
FROM subscriptions s
JOIN CUSTOMERS c
    ON s.customer_id = c.customer_id
JOIN usage_logs u
    on u.customer_id = c.customer_id
WHERE s.end_date IS NOT NULL
GROUP BY u.reports_generated
ORDER BY churned_customers DESC;

