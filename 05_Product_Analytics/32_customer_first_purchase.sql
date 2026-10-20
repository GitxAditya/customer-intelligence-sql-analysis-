use customer_intelligence_db;

-- --------------------------------------------------Ques 39
with customer_first_purchase as(
	select
		c.cust_id,
        min(o.order_date) as first_purchase_date
	from customers c
    inner join orders o on c.cust_id = o.cust_id
    where o.order_status in ('delivered', 'shipped')
    group by c.cust_id
),
campaign_acquisition as (
    select
        mc.campaign_id,
        mc.campaign_name,
        mc.campaign_type,
        mc.budget as campaign_budget,
        mc.start_date,
        mc.end_date,
        count(distinct c.cust_id) as customers_reached,
        count(distinct cfp.cust_id) as new_customers,
        coalesce(round(sum(oi.quantity*oi.selling_price),2),0) as revenue_from_new_customers
	from marketing_campaigns mc
    left join customer_campaigns cc on mc.campaign_id = cc.campaign_id
    left join customers c on cc.cust_id = c.cust_id
    left join customer_first_purchase cfp on c.cust_id = cfp.cust_id
		and cfp.first_purchase_date between mc.start_date and mc.end_date
	left join orders o on c.cust_id = o.cust_id
        and o.order_status in ('delivered', 'shipped')
        and o.order_date between mc.start_date and mc.end_date
    left join order_items oi on o.order_id = oi.order_id
    group by mc.campaign_id, mc.campaign_name, mc.campaign_type, mc.budget, mc.start_date, mc.end_date
),
cpa as (
	select *,
    round(campaign_budget / nullif(new_customers, 0), 2) as cpa
	from campaign_acquisition
)
select
	rank() over(order by cpa asc) as cpa_rank,
	campaign_name,
    campaign_type,
    campaign_budget,
    customers_reached,
    new_customers,
    cpa,
    revenue_from_new_customers,
    round(revenue_from_new_customers / nullif(new_customers,0),2) as revenue_per_customer,
    round(revenue_from_new_customers - campaign_budget, 2) as profit,
    case
		when campaign_budget = 0 then 0
        else  round(100.0 * (revenue_from_new_customers - campaign_budget) / campaign_budget, 2)
    end as roi_percent,
    case
		when cpa <= 500 then 'low cpa'
        when cpa <= 1000 then 'moderate cpa'
        when cpa <= 2000 then 'high cpa'
        else 'very high cpa'
    end as cpa_category,
    case
		when round(100.0 * (revenue_from_new_customers - campaign_budget) / campaign_budget, 2) >= 50 then 'excellent roi'
        when round(100.0 * (revenue_from_new_customers - campaign_budget) / campaign_budget, 2) >= 20 then 'good roi'
        when round(100.0 * (revenue_from_new_customers - campaign_budget) / campaign_budget, 2) >= 0 then 'break even'
        else 'loss'
    end as roi_category
from cpa
where campaign_budget > 0
order by cpa_rank;