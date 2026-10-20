use customer_intelligence_db;

-- ----------------------------------------------------------Ques 33
with channel_performance as(
	select
        mc.campaign_type,
        count(distinct cc.cust_id) as customers_reached,
        count(distinct mc.campaign_id) as total_campaigns,
        count(distinct case when cc.campaign_status = 'Clicked' then cc.cust_id end) as clicks,
        count(distinct case when cc.campaign_status = 'Purchased' then cc.cust_id end) as conversions,
        round(sum(mc.budget), 2) AS total_budget,
        coalesce(round(sum(oi.quantity*oi.selling_price),2),0) as revenue_generated,
        coalesce(round(sum(oi.quantity*oi.selling_price) - sum(mc.budget) ,2),0) as profit
	from marketing_campaigns mc
    left join customer_campaigns cc on mc.campaign_id = cc.campaign_id
    left join customers c on cc.cust_id = c.cust_id
    left join orders o on c.cust_id = o.cust_id
    left join order_items oi on o.order_id = oi.order_id
    where o.order_status in ('Delivered', 'Shipped') or o.order_status is null
    group by mc.campaign_type
)
select
	rank() over(order by roi_percent desc) as channel_rank,
	campaign_type,
    total_campaigns,
    customers_reached,
    clicks,
    conversions,
    round(100.0 * clicks / nullif(customers_reached, 0), 2) as click_through_rate,
    round(100* conversions / nullif(customers_reached, 0), 2) as conversion_rate,
    round(conversions / nullif(total_campaigns, 0), 2) as avg_conversions_per_campaign,
	total_budget,
    revenue_generated,
    profit,
    roi_percent,
	case
		when  roi_percent >= 100 then 'Excellent'
        when  roi_percent >= 50 then 'Good'
        when  roi_percent >= 20 then 'Average'
        when  roi_percent >= 0 then 'Poor'
        else "Negative"
	end as channel_performance
    from (
		select
			*,
            case
				when total_budget = 0 then 0
                else round(100.0 * profit / total_budget, 2)
			end as roi_percent
		from channel_performance
    ) as channel_roi
    where total_budget > 0
    order by channel_rank;