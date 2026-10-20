# Product & Profitability Findings

## Finding 1: High Revenue Correlates with High Profit Margins (No "Loss Leaders" in Top Tier)

**Business question:**  
Which products generate the highest absolute profit, and what are their profit margins?

**SQL file:**  
`23_product_profit.sql`

**Analysis period:**  
Overall dataset

**Evidence:**
- The **Godrej Office Chair** is the top profit generator, yielding a gross profit of **$5,669,144.78** on $16.35M in revenue.
- Top-tier products maintain robust margins. The chair has a **34.67%** margin. The American Tourister Backpack sits at **34.06%** ($4.86M profit).
- Out of the top 16 products shown, all fall into the "Good Margin" category (the lowest in the visible top 16 is the Urban Ladder Office Chair at **15.90%**).

**Observation:**  
The highest-revenue products are also the most profitable in absolute terms, and they carry healthy percentage margins. There is no indication that the business is selling high volumes of products at a loss to drive traffic.

**Business interpretation:**  
The core product catalog is highly optimized for profitability. Marketing spend should double down on these "Good Margin" items (Furniture, Accessories, Home Appliances) because every unit sold contributes significantly to covering fixed costs.

**Limitations:**  
The screenshot only shows the top 17 products by profit. We cannot see the tail end of the catalog to identify if there are low-margin or negative-margin products dragging down overall profitability.

**Follow-up question:**  
Which specific products have the lowest profit margins, and should they be discontinued or repriced?

---

## Finding 2: Top-Rated Products Might Not Be the Top Revenue Drivers

**Business question:**  
Which products have the highest customer ratings, and how does that align with revenue?

**SQL file:**  
`24_product_rating.sql`

**Analysis period:**  
Overall dataset

**Evidence:**
- The **Oswaal Novel** (Books) is the top-rated product with a near-perfect **4.88** average rating out of 456 reviews.
- However, its revenue is only **$13.58M**, which is lower than the #5 product on this list (Godrej Office Chair at $12.87M but with fewer reviews) and much lower than other top revenue products seen in previous analyses.
- Conversely, the **Godrej Office Chair** ranks 5th in ratings (4.70) but generates massive revenue ($12.87M in this specific view).

**Observation:**  
There is a slight disconnect between rating and revenue. Books and Toys dominate the top ratings (Oswaal Novel, Arihant Novel, Funskool Puzzle), while high-revenue items (like Furniture) have slightly lower average ratings (though still excellent at 4.70).

**Business interpretation:**  
Highly rated products are great for brand trust and organic traffic, but they aren't necessarily the main financial engines. The business should use highly-rated, lower-cost items (like novels or toys) as "hook" products in bundles to drive customer acquisition, while relying on furniture/appliances for actual revenue.

**Limitations:**  
The query only shows the top 17 rated products. We don't see the correlation across the entire catalog (e.g., are there 5-star products with near-zero sales?).

**Follow-up question:**  
Do customers who buy the top-rated "hook" products (like books) eventually graduate to buying high-ticket furniture?

---

## Finding 3: Wishlist Conversion Rates are Mathematically Flawed (Data Anomaly)

**Business question:**  
Which products have the highest wishlist-to-purchase conversion rates?

**SQL file:**  
`25_wishlist_conversion.sql`

**Analysis period:**  
Overall dataset

**Evidence:**
- The **Philips Vacuum Cleaner** ranks #1 with a **4800.00%** conversion rate.
- This is calculated because there was only **1** wishlist count, but **48** purchases.
- The same anomaly applies to the rest of the list: Yonex Cricket Bat (2 wishlist, 62 purchases = 3100%), Puma Hoodie (3 wishlist, 64 purchases = 2133%).

**Observation:**  
The data shows mathematically impossible conversion rates. You cannot have 48 purchases originate from 1 wishlist addition. 

**Business interpretation:**  
**Important:** The wishlist tracking feature is likely broken, or the "purchase count" is pulling total units sold regardless of whether they were ever wishlisted. These metrics cannot be used for decision-making in their current state.

**Limitations:**  
The output is heavily skewed by the low denominator (wishlist count). The data integrity between the `wishlists` table and `order_items` table is compromised.

**Follow-up question:**  
Is the `wishlist_count` only tracking current active wishlists (meaning items are removed upon purchase), while `purchase_count` tracks lifetime sales? If so, the metric needs to be restructured.

---

## Finding 4: High-Ticket Furniture Items are Frequently Bought Together

**Business question:**  
What products are frequently purchased together in the same order (Market Basket Analysis)?

**SQL file:**  
`26_order_products.sql`

**Analysis period:**  
Overall dataset

**Evidence:**
- The strongest pairing is **Nilkamal Sofa + Nilkamal Office Chair**, bought together **6** times.
- The next strongest pairings (5 times each) show a mix of cross-category buying: Aashirvaad Coffee + Cosco Football, Lego Building Blocks + Urban Ladder Office Chair, and Mamaearth Lipstick + Godrej Bookshelf.
- Confidence scores show that if someone buys a Nilkamal Sofa, there is a **12.24%** chance they buy the Office Chair in the same transaction.

**Observation:**  
Customers buying home office or living room furniture (Sofa + Chair) tend to bundle them. Interestingly, there are also random cross-category pairings (Groceries + Sports, Beauty + Furniture). 

**Business interpretation:**  
There is a clear opportunity for an "Office Setup" or "Living Room" bundle promotion featuring Nilkamal products. For the random pairings, these may be driven by corporate buyers (e.g., an office buying coffee and a football table for a breakroom).

**Limitations:**  
The query only shows pairs with at least 4 occurrences. The overall frequency of these pairs is low compared to total orders, suggesting the business doesn't have massive, predictable bundling patterns yet.

**Follow-up question:**  
Are these paired purchases made by B2B customers (Corporate) or regular retail consumers?

---

## Finding 5: Extremely Low Return Rates Across the Board

**Business question:**  
Which products have the highest return rates, and what is the financial impact?

**SQL file:**  
`27_product_returns.sql`

**Analysis period:**  
Overall dataset

**Evidence:**
- The **Nilkamal Office Chair** has the highest return rate at just **1.30%** (3 units returned out of 230 sold).
- Every other product on the list has a return rate under 1% (e.g., Arihant Exam Guide at 1.19%, Saffola Coffee at 1.08%).
- The financial impact is minimal; the highest revenue lost to returns is only **$169,950.78** on the office chair.

**Observation:**  
The return rate is incredibly low. The risk level for all visible products is categorized as "Very Low."

**Business interpretation:**  
This is a massive strength. It indicates high product quality, accurate product descriptions, and excellent packaging/shipping. The business does not have a systemic issue with buyer's remorse or damaged goods.

**Limitations:**  
The screenshot shows the *top* returned products, but they still have very low rates. We cannot see if there are specific products with high return rates in the lower ranks, though the threshold for the "Very Low" category suggests the whole catalog is performing well.

**Follow-up question:**  
What is the total cost of processing these returns (shipping + restocking), and can we reduce that operational cost further?

---

## Finding 6: Products are Selling Out Extremely Fast

**Business question:**  
What is the inventory turnover ratio, and which products are at risk of stockouts?

**SQL file:**  
`28_product_inventory.sql`

**Analysis period:**  
Overall dataset (snapshot)

**Evidence:**
- The **HarperCollins Dictionary** is moving incredibly fast. It has `current_stock` of **1**, but has sold **211** units. This gives it an inventory turnover ratio of **211.00** and only **2** days of inventory left.
- This pattern is consistent for the top items: The Lenovo Laptop has 1 in stock, sold 207 (ratio 207). The Skybags Laptop Sleeve has 1 in stock, sold 205 (ratio 205).
- All visible items are categorized as "Fast Moving."

**Observation:**  
The business is operating on a razor-thin inventory margin for its top items. They are constantly on the verge of going out of stock.

**Business interpretation:**  
While fast-moving inventory is usually good, this looks like a supply chain vulnerability. If a shipment is delayed, these top products will go out of stock immediately, costing massive lost revenue. The business is likely operating on a Just-In-Time (JIT) model that may be too lean.

**Limitations:**  
This is a point-in-time snapshot. We don't know the lead time from the supplier to calculate a true reorder point.

**Follow-up question:**  
How many days does it take for a reorder to arrive from the supplier, and are we currently experiencing stockouts on high-demand items?

---

## Finding 7: Severe Overstocking of "Very Slow" Moving Items

**Business question:**  
Which products are overstocked and not selling, requiring clearance or promotional intervention?

**SQL file:**  
`29_product_inventory_health.sql`

**Analysis period:**  
Current snapshot

**Evidence:**
- The **Levi's T-Shirt** is the biggest liability. It has **451** units in stock, but its last sale was over 435 days ago (Aug 2025).
- The Nestle Honey has 191 units in stock, with no sales in 421 days.
- All items on this list are tagged as "Very Slow" with a recommendation of "Heavy Discount or Bundle."

**Observation:**  
While top items have 1 unit left in stock, these items are sitting on massive quantities of dead inventory. 

**Business interpretation:**  
Capital is tied up in unsold goods taking up warehouse space. The business needs to urgently run a clearance sale, bundle these items with fast-movers, or write them off. 

**Limitations:**  
We don't see the `inventory_value` tied up in these slow-moving items (though the column exists, the values are cut off in the screenshot).

**Follow-up question:**  
What is the total financial value of the "Very Slow" inventory that needs to be cleared?

---

## Finding 8: The "Long Tail" of Revenue

**Business question:**  
How does the Pareto Principle (80/20 rule) apply to product revenue?

**SQL file:**  
`30_product_revenue.sql`

**Analysis period:**  
Overall dataset

**Evidence:**
- The top product (Godrej Office Chair) generates **0.59%** of total revenue.
- To reach just **8.44%** of cumulative revenue, you need to combine the top 17 products.
- The ABC categorization places all these top products in "A - Top Revenue" with "High Priority".

**Observation:**  
Revenue is heavily distributed. There is no single "hero" product. It takes dozens of products to make a significant dent in total revenue.

**Business interpretation:**  
The company is not reliant on a single product failing. However, it means that marketing campaigns cannot just focus on one item; they must push the entire top tier of products. 

**Limitations:**  
We cannot see where the "B" and "C" categories begin in this screenshot. 

**Follow-up question:**  
How many products make up the "C" category, and what percentage of revenue do they actually contribute?

---

## Finding 9: High Intent Doesn't Always Lead to Repeat Purchases

**Business question:**  
How effective is the marketing funnel from Sent to Purchase?

**SQL file:**  
`31_funnel_data.sql`

**Analysis period:**  
Overall dataset

**Evidence:**
- The funnel starts with **7,219** users sent a campaign.
- **82.52%** open the campaign (5,957 users).
- **42.67%** click through (3,080 users).
- Only **16.22%** ultimately purchase (1,171 users).
- A tiny fraction (**0.83%** of the total sent, or 60 users) become "Repeat Purchased."

**Observation:**  
Top-of-funnel engagement is excellent (Open rate > 80%). Mid-funnel is decent (Click rate > 40%). But conversion to purchase is low (16%), and retaining them for a second purchase via the campaign is almost non-existent.

**Business interpretation:**  
The marketing team is great at getting attention, but the landing pages, pricing, or checkout process might be failing to close the deal. Furthermore, the campaigns are not designed to drive loyalty—they are purely acquisition-focused.

**Limitations:**  
We don't know what the campaigns were (e.g., a welcome email vs. a clearance sale).

**Follow-up question:**  
Why is the drop-off between "Clicked" and "Purchased" so steep (61.98% drop)? Is there a technical issue with the checkout page?

---

## Finding 10: Marketing Campaigns Have Terrible ROI Tracking Data

**Business question:**  
Which marketing campaigns drive new customers, and what is their CPA and ROI?

**SQL file:**  
`32_customer_first_purchase.sql`

**Analysis period:**  
Overall dataset

**Evidence:**
- The top campaign by "CPA Rank" is the **New Year Bonanza** (Seasonal). It reached 367 customers but generated **0** new customers. Its `cpa` is `NULL`.
- The **Black Friday** campaign ranks 8th. It reached 357 customers but only generated **6** new customers. It had a CPA of $49,016.83.
- Despite this, the ROI for almost every campaign shown is listed as "excellent" with over 400% returns.

**Observation:**  
There is a massive disconnect in the data. A campaign that reaches 367 people and generates 0 new customers is ranked #1. The ROIs look artificially inflated, likely because the revenue from *existing* customers is being incorrectly attributed to the campaign.

**Business interpretation:**  
**Important:** The data here is highly suspect. If a campaign is generating $10M in revenue but $0 new customers, it means you are just harvesting your existing VIP base and calling it "new" revenue. The business needs to fix its attribution modeling to see true CPA.

**Limitations:**  
The `new_customers` count is completely broken or the campaigns genuinely failed to acquire anyone. The ROI calculation is likely counting all revenue during the campaign period, not just revenue from new customers.

**Follow-up question:**  
How is the database determining if a customer is "new" in relation to a campaign? Why are campaigns with 0 new customers showing millions in revenue?