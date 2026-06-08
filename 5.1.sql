with churned as (

select
    date_trunc(month,end_date) as churned_month,
    count(distinct customer_id) as churned_cust,
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