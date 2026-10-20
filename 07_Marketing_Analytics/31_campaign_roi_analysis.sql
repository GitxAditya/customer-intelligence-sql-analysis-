use customer_intelligence_db;

-- -------------------------------------------------------------Ques 31
with  campaign_revenue as(
	select
		mc.campaign_id,
        mc.campaign_name,
        mc.campaign_type,
        mc.budget,
        mc.start_date,
        mc.end_date,
        count(distinct cc.cust_id) as customers_reached,
        count(distinct case when cc.campaign_status = 'Clicked' then cc.cust_id end) as clicks,
        count(distinct case when cc.campaign_status = 'Purchased' then cc.cust_id end) as conversions,
        coalesce(round(sum(oi.quantity*oi.selling_price),2),0) as revenue_generated,
        coalesce(round(sum(oi.quantity*oi.selling_price) - mc.budget ,2),0) as profit
	from marketing_campaigns mc
    left join customer_campaigns cc on mc.campaign_id = cc.campaign_id
    left join customers c on cc.cust_id = c.cust_id
    left join orders o on c.cust_id = o.cust_id
    left join order_items oi on o.order_id = oi.order_id
    where o.order_status in ('Delivered', 'Shipped') or o.order_status is null
    group by mc.campaign_id, mc.campaign_name, mc.campaign_type, mc.budget, mc.start_date, mc.end_date
)
select
	rank() over(order by roi_percent desc) as roi_rank,
    campaign_name,
    campaign_type,
    budget,
    customers_reached,
    clicks,
    conversions,
    round(100* clicks/nullif(customers_reached,0),2) as click_through_rate,
    round(100* conversions/ nullif(clicks,0),2) as conversion_rate,
    revenue_generated,
    profit,
    roi_percent,
    case
		when roi_percent >= 100 then "Excellent ROI"
        when roi_percent >= 50 then "Good ROI"
        when roi_percent >= 20 then "Average ROI"
        when roi_percent > 0 then "Poor ROI"
        else "Negative ROI"
	end as roi_category
    from (
		select
			*,
            case 
				when budget = 0 then 0
                else round(100* (revenue_generated - budget) / budget, 2)
			end as roi_percent
		from campaign_revenue
	) as campaign_roi
    where budget > 0
    order by roi_rank