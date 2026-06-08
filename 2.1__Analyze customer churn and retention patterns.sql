--2.Analyze customer churn and retention patterns:
--2.1 Overall and cohort-based churn rates

with churned as (

select
    date_trunc(month,end_date) as churned_month,
    count(customer_id) as churned_cust
from
subscriptions
where
    end_date is not null
group by 
date_trunc(month,end_date)
order by churned_month
)
, active_customer as (

select
    date_trunc(month,start_date) as month,
    count(customer_id) as active_cust
from
subscriptions
where
    end_date is null
group by 
date_trunc(month,start_date)
order by month
)

select
    *,
    round(
    churned_cust /  (select 
                    count(customer_id) from                                       subscriptions) * 100,2)
                    as churn_pct
from
    churned c
join active_customer a
on c.churned_month = a.month





-----5.Business Impact & Decision Intelligence:
---- Revenue impact of churn reduction scenarios
with churned as (

select
    date_trunc(month,end_date) as churned_month,
    count(customer_id) as churned_cust,
    mrr
from
subscriptions
where
    end_date is not null
group by 
date_trunc(month,end_date),
mrr 
order by churned_month
)


, churn_revenue as(
select
sum(mrr) as lost_revenue_from_churn,
(select sum(mrr)from subscriptions)- sum(mrr) as Revenue_post_churn
from churned 
)

select
    Revenue_post_churn as no_churn_reduction,
 -- 5% reduction
    (lost_revenue_from_churn * 0.05) as                           five_pct_reduction_in_churn,
    
    Revenue_post_churn + (lost_revenue_from_churn * 0.05)
    as impact_on_total_mrr,


 -- 10% reduction
    (lost_revenue_from_churn * 0.10) as                           ten_pct_reduction_in_churn,
    
    Revenue_post_churn + (lost_revenue_from_churn * 0.10)
    as impact_on_total_mrr,


 -- 20% reduction
    (lost_revenue_from_churn * 0.20) as                           twenty_pct_reduction_in_churn,
    
    Revenue_post_churn + (lost_revenue_from_churn * 0.20)
    as impact_on_total_mrr
from churn_revenue 