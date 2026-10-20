# Sales & Revenue Analysis Findings

## Finding 1: Revenue Exhibits High Monthly Volatility but Steady Long-Term Growth

**Business question:**  
What is the monthly revenue trend, and how does the running total look throughout the year?

**SQL file:**  
`11_monthly_revenue_growth_analysis.sql` 

**Analysis period:**  
January 2022 to mid-2023 (based on visible rows)

**Evidence:**
- Monthly revenue fluctuates significantly, ranging from $44.7M (Jan 2022) to $58.8M (Apr 2022).
- Month-over-month growth percentages swing wildly (e.g., -21.89% in June 2022, followed by +23.03% in July 2022).
- The running revenue cumulative total consistently climbs, reaching over $88M by May 2023.

**Observation:**  
While there is a clear upward trend in total accumulated revenue, monthly performance is highly erratic. The business does not experience a smooth, linear growth path; instead, it alternates between strong peaks and sharp dips.

**Business interpretation:**  
The volatility suggests a reliance on specific high-ticket sales or campaign pushes rather than consistent daily demand. Financial planning must account for these lean months (like June 2022) to maintain operational stability. 

**Limitations:**  
The exact causes of the revenue spikes/dips (e.g., a massive B2B order or a holiday promotion) cannot be determined from this output alone. 

**Follow-up question:**  
What specific events or product launches occurred during the high-growth months (April 2022, July 2022) that caused the spikes, and can they be replicated?

---

## Finding 2: Extreme Daily Revenue Swings

**Business question:**  
How volatile is revenue on a day-to-day basis, and what are the highest and lowest performing days?

**SQL file:**  
`12_daily_sales_trend_analysis.sql` 

**Analysis period:**  
December 2025 (based on visible rows)

**Evidence:**
- Daily revenue swings are massive. For example, December 24, 2025, generated only $251,578.60, while December 25, 2025, spiked to $2,640,702.90 (a 949.65% increase).
- However, this is immediately followed by a drop to $808,694.33 on December 26 (-69.38%).
- Similar extreme volatility is seen around December 16 (+192.08%) and December 28 (+819.44%).

**Observation:**  
Daily revenue is not stable. It frequently jumps by hundreds of percent from one day to the next. 

**Business interpretation:**  
This pattern strongly indicates that a few large transactions (whales) are driving daily totals, rather than a steady stream of smaller retail purchases. Operations and customer service teams must be prepared for these random massive volume days.

**Limitations:**  
The screenshot only shows December 2025. It is unclear if this extreme end-of-year volatility is typical for the whole year or driven by holiday/end-of-year B2B purchasing.

**Follow-up question:**  
Are the massive daily spikes (like on Dec 25) driven by a single large customer or a specific product?

---

## Finding 3: The Business Lacks Strong Seasonality, Relying on General Market Momentum

**Business question:**  
Is there a seasonal pattern to sales (e.g., do we always sell more in Q2 or Fall?), and which quarters perform best?

**SQL file:**  
`13_seasonal_sales_trends.sql`

**Analysis period:**  
Q1 2022 to Q4 2025

**Evidence:**
- Revenue is remarkably consistent across seasons over the years. 
- Q2 2022 generated $162.7M, while Q4 2022 generated $159.6M. 
- In 2025, Q2 (Spring) generated $171.9M, while Q4 (Fall) generated $155.7M.
- The revenue percentage contribution per quarter stays tightly bound between roughly 5.7% and 6.8% of the multi-year total.

**Observation:**  
There is no distinct "peak season" or "dead season." The business performs relatively evenly across Winter, Spring, Summer, and Fall.

**Business interpretation:**  
The business model is not heavily reliant on holiday shopping (like Q4 retail) or seasonal weather changes. This is a strength, as it provides stable, predictable baseline cash flow year-round. Marketing budgets can be spread evenly rather than concentrated in one quarter.

**Limitations:**  
While revenue is flat, the *type* of products sold might shift seasonally (e.g., heaters in winter, fans in summer). The output only shows aggregate revenue.

**Follow-up question:**  
Even though total revenue is stable, does the product mix (category sales) shift significantly between Q1 and Q3?

---

## Finding 4: Revenue is Evenly Distributed Among Top Products, Not a Winner-Take-All

**Business question:**  
Which products generate the most revenue, and do we have a "hero product" that dominates sales?

**SQL file:**  
`14_product_revenue_pareto_analysis.sql` 

**Analysis period:**  
Overall dataset

**Evidence:**
- The top product is the Godrej Office Chair, generating $16.35M.
- The next few products are incredibly close: American Tourister Backpack ($14.27M), Prestige Iron ($14.17M), and American Tourister Wallet ($13.21M).
- The revenue share percentage for the top product is only 0.65%. To reach 8.57% cumulative revenue, it takes the top 17 products combined.

**Observation:**  
There is no single runaway bestseller. The top 17 products all perform within a few million dollars of each other. Furniture, Accessories, and Home Appliances all feature prominently in the top ranks.

**Business interpretation:**  
The company has a highly diversified product portfolio. It is not at risk of collapsing if one product goes out of stock or loses popularity. However, it also means marketing cannot rely on pushing just one "hero" item; it must manage a broad catalog.

**Limitations:** 
The screenshot cuts off at rank 17. We cannot see the "long tail" of products to know exactly how many items contribute to the remaining 91% of revenue.

**Follow-up question:**  
What are the profit margins on these top 4 items? A high-revenue item with low margin (like the office chair) might be less valuable than a slightly lower-revenue item with high margin.

---

## Finding 5: High-Value Transactions Consist of Bulk Purchases (Large Baskets)

**Business question:**  
What does a typical high-value order look like in terms of basket size?

**SQL file:**  
`15_basket_analysis.sql`

**Analysis period:**  
Overall dataset

**Evidence:**
- The top orders (by value) are all classified as "Large Basket."
- For example, Order 2049 (Nov 2024) had an `order_value` of $1.75M. It contained 10 distinct products and 39 total units.
- Order 1469 (Jan 2023) had an `order_value` of $1.31M, with 8 distinct products and 37 units.

**Observation:**  
The largest transactions are not single-item purchases; they are bulk orders. Customers are buying multiple distinct items (up to 12) and high quantities (up to 39 units) in a single checkout.

**Business interpretation:**  
This strongly suggests B2B transactions (e.g., offices buying furniture/appliances in bulk) rather than individual consumers. The sales team should prioritize account management for these clients, and the e-commerce platform should ensure a smooth checkout experience for large bulk orders.

**Limitations:**  
The query only shows the top largest baskets. We don't see the average basket size across the whole platform.

**Follow-up question:**  
What percentage of total revenue comes from "Large Baskets" (e.g., >10 units) versus standard retail purchases?

---

## Finding 6: Average Order Value (AOV) is Declining Over Time

**Business question:**  
How is the Average Order Value trending month-over-month?

**SQL file:**  
`16_aov_analysis.sql` 

**Analysis period:**  
January 2022 to mid-2023

**Evidence:**
- January 2022 started with a strong AOV of $366,703.61.
- The AOV shows a general downward trend over the next year and a half.
- By May 2023, the AOV had dropped to $373,577.19 (with several months in between dropping much lower, such as $331,445 in Jan 2023).
- Growth percentages are mostly negative or small until a spike in May 2023 (+10.14%).

**Observation:**  
While total revenue might be growing (seen in Finding 1), the average size of each transaction is shrinking. 

**Business interpretation:**  
The business may be acquiring more customers who make smaller purchases, diluting the impact of the massive bulk buyers. If AOV drops too low, the cost of fulfillment and acquisition per order will eat into profit margins. The company needs to implement upselling or bundling strategies.

**Limitations:**  
We cannot tell if the AOV drop is due to *all* customers spending less, or if it's a mix shift (many new small buyers joining, while the big B2B buyers stay the same).

**Follow-up question:**  
Is the AOV drop driven by specific product categories losing value, or is it a shift in customer demographics?

---

## Finding 7: Mondays and Wednesdays are the Most Profitable Days

**Business question:**  
Which days of the week generate the most revenue, and when should marketing campaigns be launched?

**SQL file:**  
`17_weekday_sales_analysis.sql` 

**Analysis period:**  
Overall dataset

**Evidence:**
- **Monday** is the highest revenue day, generating $384.3M (15.24% share), followed closely by **Wednesday** ($379.2M, 15.04%).
- **Friday** is the lowest revenue day ($341.3M, 13.53%).
- The spread between the best and worst day is relatively tight (about 1.7% difference in total revenue share).

**Observation:**  
Sales are relatively balanced throughout the week, but early weekdays (Mon-Wed) consistently outperform the end of the week (Thu-Fri). 

**Business interpretation:**  
This confirms the B2B nature of the business. Corporate buyers are likely placing orders during the workweek, especially at the start of the week. Marketing emails, sales calls, and promotions should be timed for Monday and Tuesday to capture this active buying window.

**Limitations:**  
This is an aggregate view across years. It doesn't show if holidays or end-of-month business logic changes this trend.

**Follow-up question:**  
Are the high-value "Large Baskets" (from Finding 5) placed mostly on Mondays?