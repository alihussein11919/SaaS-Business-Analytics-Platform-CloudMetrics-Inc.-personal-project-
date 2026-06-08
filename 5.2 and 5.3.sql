-- 2.1 Feature Adoption by Customer Segment
-- ────────────────────────────────────────────────────────────────────────────

-- Define feature usage thresholds and measure adoption
WITH feature_usage AS (
    SELECT 
        c.customer_id,
        c.company_size,
        i.industry_name,
        p.tier,
        s.status,
        s.mrr,
        -- Feature proxies based on usage data
        AVG(u.api_calls) AS avg_api_calls,
        AVG(u.reports_generated) AS avg_reports_generated,
        AVG(u.active_users) AS avg_active_users,
        AVG(u.storage_used_gb) AS avg_storage_used,
        -- Feature adoption flags (you can adjust thresholds)
        CASE WHEN AVG(u.api_calls) > 1000 THEN 1 ELSE 0 END AS api_power_user,
        CASE WHEN AVG(u.reports_generated) > 10 THEN 1 ELSE 0 END AS reporting_user,
        CASE WHEN AVG(u.active_users) >= 3 THEN 1 ELSE 0 END AS multi_user,
        CASE WHEN AVG(u.storage_used_gb) > 5 THEN 1 ELSE 0 END AS storage_heavy_user
    FROM customers c
    JOIN subscriptions s ON c.customer_id = s.customer_id
    JOIN industries i ON c.industry_id = i.industry_id
    JOIN plans p ON s.plan_id = p.plan_id
    LEFT JOIN usage_logs u ON c.customer_id = u.customer_id
    GROUP BY c.customer_id, c.company_size, i.industry_name, p.tier, s.status, s.mrr
)
SELECT 
    tier,
    company_size,
    COUNT(DISTINCT customer_id) AS total_customers,
    SUM(api_power_user) AS api_adopters,
    ROUND(100.0 * SUM(api_power_user) / NULLIF(COUNT(DISTINCT customer_id), 0), 1) AS api_adoption_pct,
    SUM(reporting_user) AS reporting_adopters,
    ROUND(100.0 * SUM(reporting_user) / NULLIF(COUNT(DISTINCT customer_id), 0), 1) AS reporting_adoption_pct,
    SUM(multi_user) AS multi_user_adopters,
    ROUND(100.0 * SUM(multi_user) / NULLIF(COUNT(DISTINCT customer_id), 0), 1) AS multi_user_adoption_pct,
    SUM(storage_heavy_user) AS storage_adopters,
    ROUND(100.0 * SUM(storage_heavy_user) / NULLIF(COUNT(DISTINCT customer_id), 0), 1) AS storage_adoption_pct
FROM feature_usage
GROUP BY tier, company_size
ORDER BY tier, company_size;


-- ────────────────────────────────────────────────────────────────────────────
-- 2.2 Feature Adoption Impact on Retention
-- ────────────────────────────────────────────────────────────────────────────

-- Compare churn rates between feature adopters vs non-adopters
WITH feature_usage AS (
    SELECT 
        c.customer_id,
        s.status,
        s.mrr,
        p.tier,
        -- Feature adoption flags
        CASE WHEN AVG(u.api_calls) > 1000 THEN 1 ELSE 0 END AS api_power_user,
        CASE WHEN AVG(u.reports_generated) > 10 THEN 1 ELSE 0 END AS reporting_user,
        CASE WHEN AVG(u.active_users) >= 3 THEN 1 ELSE 0 END AS multi_user,
        CASE WHEN AVG(u.storage_used_gb) > 5 THEN 1 ELSE 0 END AS storage_heavy_user
    FROM customers c
    JOIN subscriptions s ON c.customer_id = s.customer_id
    JOIN plans p ON s.plan_id = p.plan_id
    LEFT JOIN usage_logs u ON c.customer_id = u.customer_id
    GROUP BY c.customer_id, s.status, s.mrr, p.tier
)
SELECT 
    'API Power Users' AS feature,
    SUM(api_power_user) AS total_adopters,
    SUM(CASE WHEN api_power_user = 1 AND status = 'CANCELLED' THEN 1 ELSE 0 END) AS churned_adopters,
    ROUND(100.0 * SUM(CASE WHEN api_power_user = 1 AND status = 'CANCELLED' THEN 1 ELSE 0 END) 
          / NULLIF(SUM(api_power_user), 0), 2) AS adopter_churn_rate,
    SUM(CASE WHEN api_power_user = 0 THEN 1 ELSE 0 END) AS total_non_adopters,
    SUM(CASE WHEN api_power_user = 0 AND status = 'CANCELLED' THEN 1 ELSE 0 END) AS churned_non_adopters,
    ROUND(100.0 * SUM(CASE WHEN api_power_user = 0 AND status = 'CANCELLED' THEN 1 ELSE 0 END) 
          / NULLIF(SUM(CASE WHEN api_power_user = 0 THEN 1 ELSE 0 END), 0), 2) AS non_adopter_churn_rate,
    ROUND(100.0 * SUM(CASE WHEN api_power_user = 0 AND status = 'CANCELLED' THEN 1 ELSE 0 END) 
          / NULLIF(SUM(CASE WHEN api_power_user = 0 THEN 1 ELSE 0 END), 0) -
          100.0 * SUM(CASE WHEN api_power_user = 1 AND status = 'CANCELLED' THEN 1 ELSE 0 END) 
          / NULLIF(SUM(api_power_user), 0), 2) AS retention_lift_pct
FROM feature_usage

UNION ALL

SELECT 
    'Reporting Users' AS feature,
    SUM(reporting_user) AS total_adopters,
    SUM(CASE WHEN reporting_user = 1 AND status = 'CANCELLED' THEN 1 ELSE 0 END) AS churned_adopters,
    ROUND(100.0 * SUM(CASE WHEN reporting_user = 1 AND status = 'CANCELLED' THEN 1 ELSE 0 END) 
          / NULLIF(SUM(reporting_user), 0), 2) AS adopter_churn_rate,
    SUM(CASE WHEN reporting_user = 0 THEN 1 ELSE 0 END) AS total_non_adopters,
    SUM(CASE WHEN reporting_user = 0 AND status = 'CANCELLED' THEN 1 ELSE 0 END) AS churned_non_adopters,
    ROUND(100.0 * SUM(CASE WHEN reporting_user = 0 AND status = 'CANCELLED' THEN 1 ELSE 0 END) 
          / NULLIF(SUM(CASE WHEN reporting_user = 0 THEN 1 ELSE 0 END), 0), 2) AS non_adopter_churn_rate,
    ROUND(100.0 * SUM(CASE WHEN reporting_user = 0 AND status = 'CANCELLED' THEN 1 ELSE 0 END) 
          / NULLIF(SUM(CASE WHEN reporting_user = 0 THEN 1 ELSE 0 END), 0) -
          100.0 * SUM(CASE WHEN reporting_user = 1 AND status = 'CANCELLED' THEN 1 ELSE 0 END) 
          / NULLIF(SUM(reporting_user), 0), 2) AS retention_lift_pct
FROM feature_usage

UNION ALL

SELECT 
    'Multi-User Collaboration' AS feature,
    SUM(multi_user) AS total_adopters,
    SUM(CASE WHEN multi_user = 1 AND status = 'CANCELLED' THEN 1 ELSE 0 END) AS churned_adopters,
    ROUND(100.0 * SUM(CASE WHEN multi_user = 1 AND status = 'CANCELLED' THEN 1 ELSE 0 END) 
          / NULLIF(SUM(multi_user), 0), 2) AS adopter_churn_rate,
    SUM(CASE WHEN multi_user = 0 THEN 1 ELSE 0 END) AS total_non_adopters,
    SUM(CASE WHEN multi_user = 0 AND status = 'CANCELLED' THEN 1 ELSE 0 END) AS churned_non_adopters,
    ROUND(100.0 * SUM(CASE WHEN multi_user = 0 AND status = 'CANCELLED' THEN 1 ELSE 0 END) 
          / NULLIF(SUM(CASE WHEN multi_user = 0 THEN 1 ELSE 0 END), 0), 2) AS non_adopter_churn_rate,
    ROUND(100.0 * SUM(CASE WHEN multi_user = 0 AND status = 'CANCELLED' THEN 1 ELSE 0 END) 
          / NULLIF(SUM(CASE WHEN multi_user = 0 THEN 1 ELSE 0 END), 0) -
          100.0 * SUM(CASE WHEN multi_user = 1 AND status = 'CANCELLED' THEN 1 ELSE 0 END) 
          / NULLIF(SUM(multi_user), 0), 2) AS retention_lift_pct
FROM feature_usage

UNION ALL

SELECT 
    'Storage Heavy Users' AS feature,
    SUM(storage_heavy_user) AS total_adopters,
    SUM(CASE WHEN storage_heavy_user = 1 AND status = 'CANCELLED' THEN 1 ELSE 0 END) AS churned_adopters,
    ROUND(100.0 * SUM(CASE WHEN storage_heavy_user = 1 AND status = 'CANCELLED' THEN 1 ELSE 0 END) 
          / NULLIF(SUM(storage_heavy_user), 0), 2) AS adopter_churn_rate,
    SUM(CASE WHEN storage_heavy_user = 0 THEN 1 ELSE 0 END) AS total_non_adopters,
    SUM(CASE WHEN storage_heavy_user = 0 AND status = 'CANCELLED' THEN 1 ELSE 0 END) AS churned_non_adopters,
    ROUND(100.0 * SUM(CASE WHEN storage_heavy_user = 0 AND status = 'CANCELLED' THEN 1 ELSE 0 END) 
          / NULLIF(SUM(CASE WHEN storage_heavy_user = 0 THEN 1 ELSE 0 END), 0), 2) AS non_adopter_churn_rate,
    ROUND(100.0 * SUM(CASE WHEN storage_heavy_user = 0 AND status = 'CANCELLED' THEN 1 ELSE 0 END) 
          / NULLIF(SUM(CASE WHEN storage_heavy_user = 0 THEN 1 ELSE 0 END), 0) -
          100.0 * SUM(CASE WHEN storage_heavy_user = 1 AND status = 'CANCELLED' THEN 1 ELSE 0 END) 
          / NULLIF(SUM(storage_heavy_user), 0), 2) AS retention_lift_pct
FROM feature_usage;


-- ────────────────────────────────────────────────────────────────────────────
-- 2.3 Feature ROI Calculation
-- ────────────────────────────────────────────────────────────────────────────

-- Calculate revenue impact of increasing feature adoption
WITH feature_impact AS (
    SELECT 
        c.customer_id,
        s.status,
        s.mrr,
        CASE WHEN AVG(u.api_calls) > 1000 THEN 1 ELSE 0 END AS api_power_user,
        CASE WHEN AVG(u.reports_generated) > 10 THEN 1 ELSE 0 END AS reporting_user,
        CASE WHEN AVG(u.active_users) >= 3 THEN 1 ELSE 0 END AS multi_user
    FROM customers c
    JOIN subscriptions s ON c.customer_id = s.customer_id
    LEFT JOIN usage_logs u ON c.customer_id = u.customer_id
    GROUP BY c.customer_id, s.status, s.mrr
),
current_metrics AS (
    SELECT 
        'API Integration' AS feature,
        SUM(CASE WHEN api_power_user = 1 THEN mrr ELSE 0 END) AS current_adopter_mrr,
        SUM(CASE WHEN api_power_user = 0 THEN mrr ELSE 0 END) AS current_non_adopter_mrr,
        100.0 * SUM(CASE WHEN api_power_user = 1 AND status = 'CANCELLED' THEN 1 ELSE 0 END) 
            / NULLIF(SUM(api_power_user), 0) AS adopter_churn_rate,
        100.0 * SUM(CASE WHEN api_power_user = 0 AND status = 'CANCELLED' THEN 1 ELSE 0 END) 
            / NULLIF(SUM(CASE WHEN api_power_user = 0 THEN 1 ELSE 0 END), 0) AS non_adopter_churn_rate,
        SUM(CASE WHEN api_power_user = 0 THEN 1 ELSE 0 END) AS non_adopters
    FROM feature_impact
    
    UNION ALL
    
    SELECT 
        'Advanced Reporting' AS feature,
        SUM(CASE WHEN reporting_user = 1 THEN mrr ELSE 0 END) AS current_adopter_mrr,
        SUM(CASE WHEN reporting_user = 0 THEN mrr ELSE 0 END) AS current_non_adopter_mrr,
        100.0 * SUM(CASE WHEN reporting_user = 1 AND status = 'CANCELLED' THEN 1 ELSE 0 END) 
            / NULLIF(SUM(reporting_user), 0) AS adopter_churn_rate,
        100.0 * SUM(CASE WHEN reporting_user = 0 AND status = 'CANCELLED' THEN 1 ELSE 0 END) 
            / NULLIF(SUM(CASE WHEN reporting_user = 0 THEN 1 ELSE 0 END), 0) AS non_adopter_churn_rate,
        SUM(CASE WHEN reporting_user = 0 THEN 1 ELSE 0 END) AS non_adopters
    FROM feature_impact
    
    UNION ALL
    
    SELECT 
        'Multi-User Access' AS feature,
        SUM(CASE WHEN multi_user = 1 THEN mrr ELSE 0 END) AS current_adopter_mrr,
        SUM(CASE WHEN multi_user = 0 THEN mrr ELSE 0 END) AS current_non_adopter_mrr,
        100.0 * SUM(CASE WHEN multi_user = 1 AND status = 'CANCELLED' THEN 1 ELSE 0 END) 
            / NULLIF(SUM(multi_user), 0) AS adopter_churn_rate,
        100.0 * SUM(CASE WHEN multi_user = 0 AND status = 'CANCELLED' THEN 1 ELSE 0 END) 
            / NULLIF(SUM(CASE WHEN multi_user = 0 THEN 1 ELSE 0 END), 0) AS non_adopter_churn_rate,
        SUM(CASE WHEN multi_user = 0 THEN 1 ELSE 0 END) AS non_adopters
    FROM feature_impact
    )
SELECT 
    feature,
    ROUND(current_adopter_mrr, 2) AS current_adopter_mrr,
    ROUND(current_non_adopter_mrr, 2) AS current_non_adopter_mrr,
    non_adopters,
    ROUND(adopter_churn_rate, 2) AS adopter_churn_pct,
    ROUND(non_adopter_churn_rate, 2) AS non_adopter_churn_pct,
    ROUND(non_adopter_churn_rate - adopter_churn_rate, 2) AS churn_reduction_pct,
    -- Scenario: Convert 25% of non-adopters
    ROUND(current_non_adopter_mrr * 0.25, 2) AS converted_mrr_25pct,
    ROUND(current_non_adopter_mrr * 0.25 * (non_adopter_churn_rate - adopter_churn_rate) / 100 * 12, 2) 
        AS annual_revenue_protected_25pct,
    -- Scenario: Convert 50% of non-adopters
    ROUND(current_non_adopter_mrr * 0.50, 2) AS converted_mrr_50pct,
    ROUND(current_non_adopter_mrr * 0.50 * (non_adopter_churn_rate - adopter_churn_rate) / 100 * 12, 2) 
        AS annual_revenue_protected_50pct
FROM current_metrics;


-----------•Support performance impact on revenue retention-------------------

SELECT 
    sa.agent_name,
    sa.team,
    sa.skill_level,
    COUNT(st.ticket_id) AS total_tickets,
    ROUND(AVG(st.resolution_hours), 2) AS avg_resolution_hours,
    ROUND(AVG(st.satisfaction_score), 2) AS avg_satisfaction_score,
    COUNT(CASE WHEN st.priority = 'CRITICAL' THEN 1 END) AS critical_tickets,
    COUNT(CASE WHEN st.priority = 'HIGH' THEN 1 END) AS high_priority_tickets,

    
    -- Customer retention metrics
    COUNT(DISTINCT st.customer_id) AS unique_customers_served,
    COUNT(DISTINCT CASE 
        WHEN s.status = 'CANCELLED' THEN st.customer_id 
    END) AS customers_churned,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN s.status = 'CANCELLED' THEN st.customer_id END) 
          / NULLIF(COUNT(DISTINCT st.customer_id), 0), 2) AS customer_churn_rate_pct
FROM support_agents sa
LEFT JOIN support_tickets st ON sa.agent_id = st.agent_id
LEFT JOIN subscriptions s ON st.customer_id = s.customer_id
GROUP BY sa.agent_name, sa.team, sa.skill_level
ORDER BY avg_satisfaction_score DESC, total_tickets DESC;


-----------•Support performance impact on revenue retention---------------
WITH customer_support_speed AS (
    SELECT 
        st.customer_id,
        AVG(st.resolution_hours) AS avg_resolution_hours,
        COUNT(st.ticket_id) AS ticket_count,
        s.status,
        s.mrr,
        AVG(st.satisfaction_score) AS avg_satisfaction
    FROM support_tickets st
    JOIN subscriptions s ON st.customer_id = s.customer_id
    GROUP BY st.customer_id, s.status, s.mrr
)
SELECT 
    CASE 
        WHEN avg_resolution_hours <= 4 THEN 'Fast (<4 hours)'
        WHEN avg_resolution_hours <= 12 THEN 'Moderate (4-12 hours)'
        WHEN avg_resolution_hours <= 24 THEN 'Slow (12-24 hours)'
        ELSE 'Very Slow (>24 hours)'
    END AS response_speed_tier,
    COUNT(DISTINCT customer_id) AS total_customers,
    SUM(mrr) AS total_mrr,
    COUNT(DISTINCT CASE WHEN status = 'CANCELLED' THEN customer_id END) AS churned_customers,
    SUM(CASE WHEN status = 'CANCELLED' THEN mrr ELSE 0 END) AS churned_mrr,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN status = 'CANCELLED' THEN customer_id END) 
          / NULLIF(COUNT(DISTINCT customer_id), 0), 2) AS churn_rate_pct,
    ROUND(AVG(avg_satisfaction), 2) AS avg_satisfaction_score,
    -- Revenue impact calculation
    SUM(CASE WHEN status = 'CANCELLED' THEN mrr ELSE 0 END) * 12 AS annual_revenue_at_risk
FROM customer_support_speed
GROUP BY response_speed_tier
ORDER BY 
    CASE response_speed_tier
        WHEN 'Fast (<4 hours)' THEN 1
        WHEN 'Moderate (4-12 hours)' THEN 2
        WHEN 'Slow (12-24 hours)' THEN 3
        ELSE 4
    END;