# Customer Intelligence Findings

## Finding 1: High-Value Customer Concentration (Customer Lifetime Value)

**Business question:**  
Who are the top-spending customers, and what is their revenue contribution?

**SQL file:**  
`01_customer_lifetime_value.sql`

**Analysis period:**  
Jan 2022 to Dec 2025 *(inferred from customer first/last purchase dates in the dataset)*

**Evidence:**
- Top-performing product (Customer): Neha Patel with a total revenue of $4,626,425.50 across 9 orders (Avg Order Value: $110,152.99).
- Other top 5 customers (Kabir Sharma, Aditya Sharma, Isha Kumar, Neha Joshi) all generated over $4.2M in revenue.
- All top 19 visible customers are segmented as "VIP".

**Observation:**  
The top tier of customers spends exceptionally high amounts (over $100k per order), and their purchase frequencies are relatively high (ranging from 4 to 10 orders each). 

**Business interpretation:**  
A very small group of VIPs generates massive revenue. The business model relies heavily on high-ticket transactions. Retaining these top 1% of customers is critical to overall business stability, as losing even one VIP represents millions in lost revenue.

**Limitations:**  
The screenshot only shows the top 19 customers. The total number of customers and the exact percentage of total revenue these VIPs represent are not visible in this specific output.

**Follow-up question:**  
What specific products or categories are these VIPs purchasing, and can we create a dedicated account management program for them?

---

## Finding 2: A Large Portion of High-Value Customers are "At Risk"

**Business question:**  
How healthy is the current customer base in terms of recency, frequency, and monetary value (RFM)?

**SQL file:**  
`02_rfm_analysis.sql`

**Analysis period:**  
Jan 2022 to Dec 2025

**Evidence:**
- Almost all visible customers in this output have an `r_score` of 1 and a customer segment of "At Risk".
- Despite high monetary scores (`m_score` = 5), these customers have not purchased recently. For example, Kabir Sharma last ordered on 2023-08-18 (Recency: 1,159 days).
- Even recent buyers like Isha Kumar (last order 2025-12-21) are flagged as "At Risk" due to an `r_score` of 1, implying a very strict recency threshold in the query logic.

**Observation:**  
There is a severe disconnect between loyalty (high past spend/frequency) and current engagement (low recency). The system flags almost everyone shown here as "At Risk."

**Business interpretation:**  
The business has a major churn problem among its best customers. They bought heavily in the past but have stopped purchasing. If the recency threshold is accurate, the company is currently bleeding its most valuable historical accounts.

**Limitations:**  
The exact threshold for an `r_score` of 1 is not visible in the query snippet. It is also unclear if the "At Risk" segment is a large majority of the database or just a heavily filtered view.

**Follow-up question:**  
What is the specific `DATEDIFF` threshold used to calculate the `r_score`? How many "At Risk" customers have actually churned vs. are just seasonal buyers?

---

## Finding 3: Platinum Segment Aligns with Lifetime Value Leaders

**Business question:**  
How are customers distributed across value-based segments?

**SQL file:**  
`03_customer_segmentation.sql`

**Analysis period:**  
Jan 2022 to Dec 2025

**Evidence:**
- The top spenders, such as Neha Patel ($4.6M), Kabir Sharma ($4.3M), and Aditya Sharma ($4.3M), are classified as "Platinum".
- They all carry a `segment_priority` of 1.
- Their Average Order Values (AOV) range from roughly $96,000 to $146,000.

**Observation:**  
The segmentation logic correctly identifies the top revenue generators (seen in Finding 1) and buckets them into the highest tier (Platinum).

**Business interpretation:**  
The segmentation model is working as intended for the top end. Marketing and retention efforts for priority 1 should focus on maintaining the AOV and frequency of this Platinum group.

**Limitations:**  
The screenshot only shows the top rows. We cannot see the distribution of Gold, Silver, or Bronze tiers to understand the full customer pyramid.

**Follow-up question:**  
What is the minimum spend threshold to reach Platinum, and how many customers actually qualify?

---

## Finding 4: Highly Reliant on Repeat Buyers

**Business question:**  
What is the ratio of repeat customers to one-time buyers, and how does their spending compare?

**SQL file:**  
`04_repeat_vs_onetime.sql`

**Analysis period:**  
Jan 2022 to Dec 2025

**Evidence:**
- **Repeat Customers:** 1,764 (90.74%), Avg Spend: $139,478.53, Avg Orders: 3.98.
- **One-time buyers:** 180 (9.26%), Avg Spend: $343,749.41, Avg Orders: 1.00.
- Total revenue from repeat customers: ~$246M vs. ~$61M from one-time buyers.

**Observation:**  
An overwhelming 90.7% of the customer base makes more than one purchase. However, one-time buyers have a significantly higher average spend per customer ($343k vs $139k).

**Business interpretation:**  
The business has excellent retention (or the products naturally force a second purchase). Interestingly, one-time buyers spend nearly 2.5x more per person than repeat buyers. This means the company acquires "whales" who buy once and leave, while the steady revenue engine is the repeat buyers. Converting those high-spend one-time buyers into a second purchase would yield massive returns.

**Limitations:**  
The data doesn't show *what* the one-time buyers purchased. They may have made a single, massive bulk order (B2B) that they don't need to repeat frequently.

**Follow-up question:**  
Why do high-spending one-time buyers not return? Is it a product lifecycle issue, or a failure in post-purchase engagement?

---

## Finding 5: Customer Acquisition Peaked Early and is Declining

**Business question:**  
What is the monthly trend of new customer acquisition?

**SQL file:**  
`05_monthly_acquisition.sql`

**Analysis period:**  
January 2022 to December 2025 *(showing Jan 2022 - May 2023)*

**Evidence:**
- Highest acquisition month shown: February 2022 with 138 new customers.
- The trend shows a steady decline over time: 138 (Feb '22) -> 65 (Dec '22) -> 45 (Feb '23) -> 43 (May '23).
- Growth percentage fluctuates but shows a general downward trend from mid-2022 onwards.

**Observation:**  
New customer acquisition is slowing down significantly. The early months of 2022 brought in the most volume, and it has been shrinking year-over-year.

**Business interpretation:**  
The company may be facing market saturation, increased competition, or a reduction in marketing spend. If acquisition continues to fall while churn (Finding 2) is high, total revenue will eventually decline.

**Limitations:**  
The data only goes up to May 2023 in the screenshot. It is unclear if there was a resurgence in late 2023 or 2024.

**Follow-up question:**  
Did marketing campaign budgets decrease in mid-2022, and what is the Customer Acquisition Cost (CAC) trend over this period?

---

## Finding 6: Strong Core Retention Rate

**Business question:**  
What percentage of customers return to make another purchase?

**SQL file:**  
`06_customer_retention.sql`

**Analysis period:**  
Jan 2022 to Dec 2025

**Evidence:**
- Returned Customers: 1,775 (91.12%), Average Orders: 4.06.
- Never Returned: 173 (8.88%), Average Orders: 1.00.

**Observation:**  
The retention rate (91.12%) closely mirrors the "Repeat Customer" metric from Finding 4. 

**Business interpretation:**  
Once a customer is acquired and makes a second purchase, they are highly likely to become a consistent, long-term buyer (averaging 4 orders). The primary leak in the bucket is that first-to-second purchase transition.

**Limitations:**  
This is an aggregate view. It does not show *how long* it takes a customer to return (days gap). 

**Follow-up question:**  
What is the average time between the 1st and 2nd purchase, and are there specific post-purchase triggers that encourage the return?

---

## Finding 7: Revenue is Geographically Concentrated

**Business question:**  
Which cities and states generate the most revenue, and are there underserved regions?

**SQL file:**  
`07_city_revenue.sql`

**Analysis period:**  
Jan 2022 to Dec 2025

**Evidence:**
- **Chennai (Tamil Nadu):** Rank 1, $193.4M revenue, 143 customers.
- **Gurugram (Haryana):** Rank 2, $192.7M revenue, 145 customers.
- **Kochi (Kerala):** Rank 3, $187.9M revenue, 143 customers.
- Top 15 cities contribute between $144M and $193M each, capturing roughly 5.71% to 7.67% revenue share.

**Observation:**  
The top cities are surprisingly evenly distributed. Chennai, Gurugram, Kochi, and Hyderabad are virtually tied in revenue. 

**Business interpretation:**  
The business does not rely on a single "home run" city (like a typical Tier-1 metro dominance). It has a remarkably balanced geographical footprint across India. This reduces localized risk but means marketing needs to be distributed across multiple regions.

**Limitations:**  
We don't see the bottom 15 cities or the total number of active cities. We also don't know the Cost of Living or regional marketing expenses, which impacts profitability per city.

**Follow-up question:**  
Are there regions where Customer Acquisition Cost is significantly lower, making them more profitable despite slightly lower revenue?

---

## Finding 8: Identification of One-Time Buyers

**Business question:**  
How can we identify and isolate new or infrequent buyers to target them for retention?

**SQL file:**  
`08_purchase_frequency.sql`

**Analysis period:**  
Jan 2022 to Dec 2025

**Evidence:**
- The output heavily features "New Customer" purchase frequencies.
- Customers like Rohan Gupta (Ahmedabad), Priya Nair (Delhi), and Aditya Sharma (Jaipur) have a `total_orders` of 1, a `days_gap` of 0, and an `avg_days_between_purchases` of 0.

**Observation:**  
The query successfully flags single-purchase customers. The `days_gap` of 0 is mathematically correct for one order, but visually might look like they bought twice on the same day.

**Business interpretation:**  
This list is the perfect target for a "Second Purchase" email sequence or a win-back coupon. Converting these users is the key to maintaining the 90% retention rate.

**Limitations:**  
Because the output is sorted by `cust_id` (or similar), we don't know *when* these customers made their first purchase. A customer from 2022 in this list is completely different from a customer from late 2025.

**Follow-up question:**  
Can we split this list into "newly acquired, yet to make 2nd purchase" vs. "long-term inactive one-timers"?

---

## Finding 9: Massive Number of Dormant (Lost) Customers

**Business question:**  
How many customers have we lost, and how much revenue did they historically generate?

**SQL file:**  
`09_dormant_customers.sql`

**Analysis period:**  
Jan 2022 to Dec 2025

**Evidence:**
- Several customers have not purchased in over 1,400 days (nearly 4 years). 
- Examples: Aisha Malhotra (1449 days), Aisha Reddy (1438 days), Vivaan Agarwal (1430 days).
- Despite being dormant for 1+ years, these customers generated significant past revenue (e.g., Aisha Reddy generated $2.15M, Rahul Kumar generated $2.42M).

**Observation:**  
There is a large pool of high-value customers who have completely stopped buying. 

**Business interpretation:**  
This confirms the "At Risk" finding (Finding 2). The company is sitting on a graveyard of former VIPs. A targeted "win-back" campaign with a high-ticket incentive might resurrect some of this lost revenue.

**Limitations:**  
We don't know *why* they left (e.g., product quality, competitor, economic reasons). The 1400+ day dormancy suggests some of these might be B2B accounts that completed their project.

**Follow-up question:**  
If we launch a win-back campaign for these lost customers, what was their favorite product category? We should lead with that.

---

## Finding 10: The Ultimate Churn Risk List

**Business question:**  
Which customers are at the highest risk of churning right now, and how can we contact them?

**SQL file:**  
`10_churn_prediction.sql`

**Analysis period:**  
Jan 2022 to Dec 2025

**Evidence:**
- A list of 1-order customers with their last purchase date over 1,600 days ago.
- Example: Sneha Malhotra (Indore) last purchased on 2022-01-03 (1,751 days ago), total revenue $699k.
- All shown customers are flagged as "High Risk".

**Observation:**  
This query acts as a contact list for churned or highly inactive users who only ever bought once. 

**Business interpretation:**  
These are "whales" who bought once (spending hundreds of thousands) and vanished. The business needs to urgently reach out to ask for feedback. Did something go wrong with the order?

**Limitations:**  
The `churn_risk_category` logic is based purely on `days_since_last_purchase` and order count. It doesn't factor in engagement (email opens, site visits) because that data isn't in the query. 

**Follow-up question:**  
Can we cross-reference this list with customer service tickets to see if these high-value one-time buyers had unresolved complaints?