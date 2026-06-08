--1 .Track Monthly Recurring Revenue (MRR) and growth trends:
--Monthly Recurring Revenue (MRR) by plan, segment, and cohort

with monthly_mrr as(
 SELECT
        s.customer_id,
        DATE_TRUNC('month', d.month) AS mrr_month,
        p.plan_name,
        c.company_size AS segment,
        SUM(s.mrr) AS mrr
    FROM subscriptions s
    JOIN customers c
        ON s.customer_id = c.customer_id
    JOIN plans p
        ON s.plan_id = p.plan_id
    JOIN (
        SELECT DISTINCT DATE_TRUNC('month', start_date) AS month
        FROM subscriptions
    ) d
     ON d.month >= s.start_date
       AND (s.end_date IS NULL OR d.month < s.end_date)
    GROUP BY
        DATE_TRUNC('month', d.month),
        p.plan_name,
        c.company_size,
        s.customer_id
ORDER BY mrr_month, plan_name, segment
)

,
cohort_month as(
select
    customer_id,
    date_trunc(month,customers.signup_date) as cohort_month
from
    customers
)

SELECT
    cm.cohort_month,
    m.mrr_month,
    SUM(m.mrr) AS cohort_mrr
FROM monthly_mrr m
JOIN cohort_month cm
    ON m.customer_id = cm.customer_id
GROUP BY cm.cohort_month, m.mrr_month
ORDER BY cm.cohort_month, m.mrr_month;

-- MRR movement breakdown: New, Expansion, Contraction, Churned
with monthly_mrr as(
select
    customer_id,
    SUM(mrr) as mrr,
    DATE_TRUNC('month', d.month) AS mrr_month
from
    subscriptions s
join 
(select 
    DISTINCT DATE_TRUNC(month, start_date) as month
from
    subscriptions) d
  ON d.month >= s.start_date
  GROUP BY
        s.customer_id,
        DATE_TRUNC('month', d.month)
)
 ,mrr_with_lag AS(
SELECT
        customer_id,
        mrr_month,
        mrr,
        lag(mrr)over(partition by customer_id order by mrr_month ,customer_id) as prev_mrr
from
    monthly_mrr
)
,mrr_movement AS (
    SELECT
        customer_id,
        mrr_month,

        CASE
            WHEN prev_mrr IS NULL AND mrr > 0
                THEN mrr
            ELSE 0
        END AS new_mrr_val,

        CASE
            WHEN mrr > prev_mrr
                THEN mrr - prev_mrr
            ELSE 0
        END AS expansion_mrr_val,

        CASE
            WHEN mrr < prev_mrr AND mrr > 0
                THEN prev_mrr - mrr
            ELSE 0
        END AS contraction_mrr_val,

        CASE
            WHEN prev_mrr > 0 AND mrr = 0
                THEN prev_mrr
            ELSE 0
        END AS churned_mrr_val
    FROM mrr_with_lag
)
SELECT
    mrr_month,
    SUM(new_mrr_val)         AS new_mrr,
    SUM(expansion_mrr_val)   AS expansion_mrr,
    SUM(contraction_mrr_val) AS contraction_mrr,
    SUM(churned_mrr_val)     AS churned_mrr
FROM mrr_movement
GROUP BY mrr_month
ORDER BY mrr_month;



-- Revenue concentration risk (top 1%, 5%, 10% of customers)
WITH current_mrr AS (
--1 indiviudal mrr for each customer
    SELECT
        s.customer_id,
        SUM(s.mrr) AS current_mrr
    FROM subscriptions s
    WHERE s.end_date IS NULL
    GROUP BY s.customer_id
)
--2 ranking each users total mrr percentage
, ranked_customers AS (
select
        customer_id,
        current_mrr,
    ntile(100)over(order by current_mrr desc) as rev_percentile
from
    current_mrr
)
SELECT
    CASE
        WHEN rev_percentile <= 1  THEN 'Top 1%'
        WHEN rev_percentile <= 5  THEN 'Top 5%'
        WHEN rev_percentile <= 10 THEN 'Top 10%'
    END AS customer_bucket,
--total mrr of each customer bucket 
    SUM(current_mrr) AS mrr_contribution,

    
--percentage of each cutomer bucket mrr out of the total mrr of all buckets--
--is calculated by [bucket level mrr/all buckets mrr * 100]--
    ROUND(
        100.0 * SUM(current_mrr)/
        SUM(SUM(current_mrr)) OVER (),
        2
    ) AS pct_of_total_mrr
FROM ranked_customers

--to limit result to only up to the top 10% of customers--
WHERE rev_percentile <= 10
GROUP BY customer_bucket
ORDER BY pct_of_total_mrr desc;


