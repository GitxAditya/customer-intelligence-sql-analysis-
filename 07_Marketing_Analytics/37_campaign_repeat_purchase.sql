use customer_intelligence_db;

-- ------------------------------------------------------Ques 37
with campaign_conversion as(
	select
		mc.campaign_id,
        mc.campaign_name,
        mc.campaign_type,
        mc.start_date,
        mc.end_date,
        count(distinct cc.cust_id) as customers_reached,
        count(distinct case 
			when o.order_date between mc.start_date and mc.end_date then cc.cust_id end) as customers_converted
	from marketing_campaigns mc
    left join customer_campaigns cc on mc.campaign_id = cc.campaign_id
    left join customers c on cc.cust_id = c.cust_id
    left join orders o on c.cust_id = o.cust_id
		and o.order_status in ('Delivered', 'Shipped')
	left join order_items oi on o.order_id = oi.order_id
    group by mc.campaign_id, mc.campaign_name, mc.campaign_type, mc.start_date, mc.end_date
),
repeat_purchase as(
	select
		cc.campaign_id,
        c.cust_id,
        min(o.order_date) as first_purchase_date,
        min(o2.order_date) as repeat_purchase_date,
        datediff(min(o2.order_date), min(o.order_date)) as days_until_repeat
	from customer_campaigns cc
    left join customers c on cc.cust_id = c.cust_id
    left join orders o on c.cust_id = o.cust_id
		and o.order_status in ('Delivered', 'Shipped')
	left join orders o2 on c.cust_id = o2.cust_id
		and o2.order_status in ('Delivered', 'Shipped') and
        o2.order_date > o.order_date
	group by cc.campaign_id, c.cust_id
    having repeat_purchase_date is not null
)
select
    mc.campaign_name,
    mc.campaign_type,
    mc.start_date,
    mc.end_date,
    cc.customers_converted,
    count(distinct rp.cust_id) as repeat_buyers,
    round(100* count(distinct rp.cust_id)/nullif(cc.customers_converted, 0), 2) as repeat_rate_percent,
    round(avg(rp.days_until_repeat),2) as avg_days_until_next_purchase,
    rank() over(order by (count(distinct rp.cust_id)/nullif(cc.customers_converted,0)) desc) as repeat_rank,
    case
		when  round(100* count(distinct rp.cust_id)/nullif(cc.customers_converted, 0), 2) >= 30 then "High Repeat"
        when  round(100* count(distinct rp.cust_id)/nullif(cc.customers_converted, 0), 2) >= 15 then "Moderate Repeat"
        when  round(100* count(distinct rp.cust_id)/nullif(cc.customers_converted, 0), 2) then "Low Repeat"
        else "Very low repeat"
	end as repeat_category
from marketing_campaigns mc
join campaign_conversion cc on mc.campaign_id = cc.campaign_id
left join repeat_purchase rp on mc.campaign_id = rp.campaign_id
group by mc.campaign_id, mc.campaign_name, mc.campaign_type, mc.start_date, mc.end_date, cc.customers_converted
order by repeat_rank;