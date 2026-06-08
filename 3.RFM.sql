with cte as(
select 
s.customer_id,
count(payment_id) frequency,

datediff(
day,
max(payment_date),
current_date()) as recency
,sum(s.mrr) as monetary,
count(st.created_date) as tickets_made
from
    payments p
join customers c
on c.customer_id = p.customer_id
join subscriptions s
on c.customer_id = s.customer_id
join support_tickets st
on s.customer_id = st.customer_id
group by s.customer_id
)

,cte2 as(
select
*,
ntile(5)over(order by recency desc) as Recency_Score,
ntile(5)over(order by frequency asc) as frequency_Score,
ntile(5)over(order by monetary asc) as monetary_Score,
ntile(5)over(order by tickets_made asc) as support_score 
from cte
)


,cte3 as(
select
    *,
    case when Recency_Score >= 4
    and frequency_Score >= 4
    and monetary_Score >=4
    then 'Top performing Customer'

     
    when recency_score <= 2
    and frequency_score <= 2
    then 'At Risk'

    when frequency_Score <= 2
    and  monetary_Score >= 4
    then 'High Value Low Engagement'

    when  frequency_Score <= 2
    and   monetary_Score <= 2
    then 'Mid tier'

    when  frequency_Score <= 2
    and   monetary_Score <= 2
    and   support_score >=3
    then 'High Cost Customer'

    else 'Mid tier'

    end as customer_identification,

        

        /* Recency risk */
        CASE
            WHEN recency > 900 THEN 3
            WHEN recency > 60 THEN 2
            WHEN recency > 30 THEN 1
            ELSE 0
        END AS recency_risk,

        /* Frequency risk */
        CASE
            WHEN frequency < 5 THEN 2
            WHEN frequency < 10 THEN 1
            ELSE 0
        END AS frequency_risk,

        /* Revenue risk */
        CASE
            WHEN monetary < 50 THEN 1
            ELSE 0
        END AS monetary_risk
        
from cte2
order by customer_id asc
)

select
*,
(recency_risk
   + frequency_risk
   + monetary_risk
   ) AS total_risk_score,

 CASE
        WHEN (recency_risk
            + frequency_risk
            + monetary_risk
            ) >= 5
            THEN 'High Risk'

        WHEN (recency_risk
            + frequency_risk
            + monetary_risk
            ) >= 3
            THEN 'Medium Risk'

        ELSE 'Low Risk'
    END AS risk_level

from cte3
ORDER BY total_risk_score DESC;



