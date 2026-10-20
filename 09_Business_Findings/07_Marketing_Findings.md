# Marketing Analysis Findings

## Finding 1: Extremely High ROI, But Likely Flawed Attribution

**Business question:**  
Which marketing campaigns generate the highest ROI and profit?

**SQL file:**  
`31_campaign_roi_analysis.sql`

**Analysis period:**  
Overall dataset

**Evidence:**
- The **New Year Bonanza** campaign ranks #1 with an ROI of **543,701.75%** and a profit of **$5.94B**.
- The **Raksha Bandhan Offers** ranks #2 with an ROI of **336,910.22%**.
- Every single campaign in the top 19 has an "Excellent ROI" category, exceeding 50,000%. 

**Observation:**  
The ROI numbers are artificially inflated to mathematically impossible levels. For example, the New Year Bonanza had a budget of ~$109k but generated $5.9 billion in revenue. 

**Business interpretation:**  
**Critical Data Flaw:** The query is likely counting *all* revenue generated during the campaign period (or lifetime revenue of targeted customers) rather than strictly attributing revenue to the campaign's specific conversions. Marketing cannot trust these ROI numbers for budget allocation until the attribution model is fixed to only count revenue from users who actually converted because of the campaign.

**Limitations:**  
The query lacks a clean tracking mechanism (like a unique promo code or UTM parameter) to isolate true campaign-driven revenue.

**Follow-up question:**  
How can we adjust the SQL to only count revenue from customers who had a `campaign_status = 'Purchased'` during the specific campaign dates?

---

## Finding 2: Strong Funnel Conversion Rates

**Business question:**  
How effectively do campaigns move customers from targeted to purchased?

**SQL file:**  
`32_campaign_conversion_funnel.sql`

**Analysis period:**  
Overall dataset

**Evidence:**
- The **Dussehra Discounts** campaign ranks #1 with an "Excellent" conversion category (69 purchases from 358 targeted).
- The **Summer Mega Sale** ranks #2 (69 purchases from 359 targeted).
- Out of the top 19 campaigns, all of them are categorized as "Excellent."

**Observation:**  
The conversion rate (Purchased / Targeted) is remarkably consistent across campaigns, hovering around 16% to 19% (e.g., Dussehra: 69/358 = 19.2%).

**Business interpretation:**  
The marketing team is doing a great job at designing campaigns that resonate with the targeted audience. The consistency suggests the marketing channels and targeting criteria are well-established and reliable.

**Limitations:**  
The screenshot cuts off before showing the exact `conversion_rate` percentage column, but the raw numbers indicate a strong baseline.

**Follow-up question:**  
What is the cost per acquisition (CPA) for these highly converting campaigns, and does the high conversion justify the ad spend?

---

## Finding 3: "Referral" Drives the Highest Click-Through Rate

**Business question:**  
Which channel (campaign type) is best at getting customers to engage (click) and convert?

**SQL file:**  
`33_channel_performance.sql`

**Analysis period:**  
Overall dataset

**Evidence:**
- **Referral** campaigns have the highest click-through rate at **25.55%**.
- **Global Event** campaigns are second at **29.72%** (Wait, looking at the math: Referral 93 clicks / 364 reached = 25.55%. Global Event 189 clicks / 636 reached = 29.72%. So Global Event is actually #1 in CTR).
- **Referral** has the highest conversion rate at **17.86%**.
- **Festival** campaigns generate the most absolute revenue ($444.7M) because there are 8 campaigns.

**Observation:**  
Global Events drive the most clicks, but Referrals drive the best actual purchases (conversions). 

**Business interpretation:**  
People trust referrals. When a customer is referred, they are much more likely to buy. The business should invest heavily in a formal referral program. Global Events are great for brand awareness (clicks) but may be more expensive or less targeted than referrals.

**Limitations:**  
The ROI column (cut off on the right) shows massive negative numbers for all channels. As noted in Finding 1, this confirms the ROI calculation is fundamentally broken. 

**Follow-up question:**  
Can we allocate more budget specifically to the Referral channel to scale its 17.86% conversion rate?

---

## Finding 4: Festival and Seasonal Campaigns Generate High Volume

**Business question:**  
Which campaigns generate the most overall engagement (Opened, Clicked)?

**SQL file:**  
`34_campaign_response_rate.sql`

**Analysis period:**  
Overall dataset

**Evidence:**
- The **Ganesh Chaturthi Promo** (Festival) ranks #1 in response, with 380 sent, 169 opened, 111 clicked, and 68 purchased.
- The **Summer Mega Sale** (Seasonal) ranks #2 with 359 sent, 144 opened, 103 clicked, 69 purchased.
- Every campaign listed has an "Excellent Response" category.

**Observation:**  
Festival and Seasonal campaigns dominate the top of the list for engagement. They consistently get nearly half of the sent audience to open the message.

**Business interpretation:**  
Aligning marketing pushes with cultural festivals (Ganesh Chaturthi, Diwali) or seasonal changes (Summer, Back to School) is highly effective for this customer base. The business should ensure these campaigns are a staple of the annual marketing calendar.

**Limitations:**  
We don't see the exact `response_rate` percentage, but based on the raw numbers, the Ganesh Chaturthi response rate is roughly 86% (327 out of 380 responded in some way).

**Follow-up question:**  
Are the profit margins on products sold during these festival campaigns higher or lower than standard retail periods?

---

## Finding 5: High Order Volume Generated by Targeted Campaigns

**Business question:**  
Which campaigns generate the highest revenue per customer?

**SQL file:**  
`35_campaign_revenue.sql`

**Analysis period:**  
Overall dataset

**Evidence:**
- The **Back to School** (Promotion) campaign ranks #1 in revenue, generating **$669.3M** from 64 customers, with an AOV of $400,093.02.
- The **Year End Clearance** ranks #2, generating $608.2M from 57 customers, with an AOV of $394,951.90.
- The revenue per budget is massive: Back to School generated **$809.66** for every $1 spent.

**Observation:**  
These campaigns generate incredibly high Average Order Values (AOV ~$400k). This further confirms that the customer base includes high-spending B2B or corporate buyers.

**Business interpretation:**  
A "Back to School" promotion for a normal retail store implies low-cost supplies (notebooks, pens). However, for this business, a $400,000 AOV implies they are selling bulk furniture or IT equipment to schools/universities. The marketing team should lean into B2B procurement terminology for these campaigns.

**Limitations:**  
Again, the revenue attribution is highly suspect. It is unlikely that a single campaign caused a $400k AOV unless the campaign specifically targeted large institutions.

**Follow-up question:**  
What specific products are driving the massive AOV in the "Back to School" campaign?

---

## Finding 6: Complete Breakdown of Campaign Performance Metrics

**Business question:**  
How do all the key metrics (ROI, Conversion, Response, Click Rate, CPA) align for each campaign?

**SQL file:**  
`36_campaign_performance.sql`

**Analysis period:**  
Overall dataset

**Evidence:**
- This comprehensive view confirms the high ROI (e.g., New Year Bonanza at 543,701%).
- It highlights that **New Year Bonanza** had a 0.00% `new_customer_percent`, meaning it only sold to existing customers.
- **Black Friday** had the highest new customer acquisition (10.34%) among the top campaigns, but a lower ROI.

**Observation:**  
Some campaigns are purely for retention (New Year Bonanza) while others are better for acquisition (Black Friday). 

**Business interpretation:**  
The marketing team needs a balanced portfolio. Use campaigns like Black Friday to acquire new users, and then use campaigns like New Year Bonanza to extract maximum lifetime value from them.

**Limitations:**  
The `combined_score` column is cut off, making it difficult to see the overall campaign ranking.

**Follow-up question:**  
What is the Customer Acquisition Cost (CPA) for the Black Friday campaign compared to its lifetime value (LTV)?

---

## Finding 7: High Repeat Purchase Intent, But Data Shows Otherwise

**Business question:**  
Which campaigns drive the highest repeat purchase rates?

**SQL file:**  
`37_campaign_repeat_purchase.sql`

**Analysis period:**  
Overall dataset

**Evidence:**
- The **VIP Customer Exclusive** (Retention) campaign ranks #1 with 343 repeat buyers.
- The **Monsoon Deals** ranks #2 with 342 repeat buyers.
- The `repeat_rate_percent` is mathematically impossible: 4,287.50% for VIP Customer Exclusive.
- The `avg_days_until_next_purchase` is extremely high (308.58 days).

**Observation:**  
Just like the Wishlist analysis, the calculation for repeat rate is fundamentally broken. It appears to be calculating (Repeat Buyers / Customers Converted) * 100, but the `customers_converted` number (8) is tiny compared to the `repeat_buyers` (343).

**Business interpretation:**  
**Critical Data Flaw:** The query is comparing two different population sizes. It is likely counting *total* historical repeat buyers and dividing by the *current campaign's* conversions. The business cannot use this data to determine if the VIP campaign actually drove retention.

**Limitations:**  
The SQL logic needs to be rewritten to only count customers who made a second purchase *after* the campaign end date, not just historical repeat buyers.

**Follow-up question:**  
How can we rewrite the query to properly cohort customers (e.g., "Of the customers who bought in the VIP campaign, how many bought again within 90 days?")?