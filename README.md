# CloudMetrics Inc. — SaaS Business Analytics Platform

SQL analytics project for a fictional B2B SaaS company (CloudMetrics Inc.), covering revenue, churn, customer segmentation, support performance and decision-support scenarios. Built in Snowflake as part of the ITI Data Management track.

## Table of Contents
- [Business Context](#business-context)
- [Dataset](#dataset)
- [1. MRR & Growth](#1-mrr--growth)
- [2. Churn & Retention](#2-churn--retention)
- [3. RFM Segmentation & Risk Scoring](#3-rfm-segmentation--risk-scoring)
- [4. Support Performance](#4-support-performance)
- [5. Business Impact & Decision Intelligence](#5-business-impact--decision-intelligence)
- [Repository Structure](#repository-structure)
- [Tech & SQL Techniques](#tech--sql-techniques)
- [Author](#author)

## Business Context
CloudMetrics Inc. sells business intelligence tools. Management needs to track revenue growth, understand churn, identify top and at-risk customers, measure support performance, and quantify the impact of retention and feature initiatives.

## Dataset
Tables: `customers`, `subscriptions`, `plans`, `industries`, `usage_logs`, `payments`, `support_tickets`, `support_agents`.

## 1. MRR & Growth
**File:** `1.Track Monthly Recurring Revenue (MRR) and growth trends.sql`

**MRR by plan, segment and cohort** — monthly MRR per customer, rolled up by signup cohort.

![MRR by cohort, plan and segment](https://github.com/user-attachments/assets/47af4ef6-c548-4959-877a-a1266e07d00f)

**MRR movement (New / Expansion / Contraction / Churned)** — `LAG()` over each customer's monthly MRR to classify the change.

![MRR movement](https://github.com/user-attachments/assets/40af82ab-9bde-4342-83cb-a1bdeee40095)

**Revenue concentration risk** — share of MRR from the top 1%, 5% and 10% of customers.

![Revenue concentration](https://github.com/user-attachments/assets/879bb739-09e8-4d16-a92d-e10743bf2c65)

## 2. Churn & Retention
**Files:** `2.1__...sql`, `2.2_2.3__...sql`
Overall and cohort churn rate, churn by tenure (early vs long-term), by plan, industry and usage level.

<!-- add screenshots -->

## 3. RFM Segmentation & Risk Scoring
**File:** `3.RFM.sql`

Raw RFM metrics per customer (recency in days, payment frequency, monetary value):

![RFM metrics](https://github.com/user-attachments/assets/2e1db44e-8a82-47bc-95f1-e70fd5c7288e)

Quintile scores (`NTILE(5)`) and the resulting segment:

![RFM scores and segments](https://github.com/user-attachments/assets/120aa045-5851-4da3-93c9-1b4c4a6afb74)

Risk scoring (recency + frequency + monetary risk → High / Medium / Low):

![Risk scoring](https://github.com/user-attachments/assets/02f31ca2-7d8c-400a-92f3-5162d4ab2ad1)

Segment definitions:

![Segment meanings](https://github.com/user-attachments/assets/67d46596-8385-4bf2-9dd8-debc4653dad4)

Customers per segment:

![Customers per segment](https://github.com/user-attachments/assets/7b6a9146-3582-4a31-9065-28c5999b8831)

## 4. Support Performance
**File:** `4.Measure support team performance and customer satisfaction_.sql`
Resolution time trends, ticket volume per customer and plan, repeat-ticket rate.

<!-- add screenshots -->

## 5. Business Impact & Decision Intelligence
**Files:** `5.1.sql`, `5.2 and 5.3.sql`
Churn-reduction revenue scenarios (5/10/20%), feature adoption vs retention, feature ROI, support impact on revenue retention.

<!-- add screenshots -->

## Repository Structure
(file list with one-line descriptions)

## Tech & SQL Techniques
Snowflake SQL · CTEs · window functions (`LAG`, `NTILE`) · `DATE_TRUNC` · `DATEDIFF` · cohort analysis · RFM scoring · scenario modeling

## Author
Ali · [LinkedIn](<link>)
