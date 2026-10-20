use customer_intelligence_db;

with campaign_performance as (
    select
        mc.campaign_id,
        mc.campaign_name,
        mc.campaign_type,
        mc.budget,
        mc.start_date,
        mc.end_date,
        count(distinct cc.cust_id) as customers_reached,
        count(distinct case when cc.campaign_status in ('opened', 'clicked', 'purchased') then cc.cust_id end) as customers_responded,
        count(distinct case when cc.campaign_status = 'clicked' then cc.cust_id end) as customers_clicked,
        count(distinct case when cc.campaign_status = 'purchased' then cc.cust_id end) as customers_converted,
		coalesce(round(sum(oi.quantity*oi.selling_price),2),0) as revenue,
        coalesce(round(sum(oi.quantity * oi.selling_price) - mc.budget, 2), 0) as profit,
        count(distinct case
			when cc.campaign_status = 'purchased'
            and exists(
				select 1
                from orders o2
                where o2.cust_id = cc.cust_id
                and o2.order_date > (select 
					min(order_date) 
                    from orders o
                    WHERE o.cust_id = cc.cust_id 
            AND o.order_date BETWEEN mc.start_date AND mc.end_date
        )
            ) then cc.cust_id
        END) AS repeat_buyers
	from marketing_campaigns mc
    left join customer_campaigns cc on mc.campaign_id = cc.campaign_id
    left join customers c on cc.cust_id = c.cust_id
    left join orders o on c.cust_id = o.cust_id
        and o.order_status in ('delivered', 'shipped')
    left join order_items oi on o.order_id = oi.order_id
    group by mc.campaign_id, mc.campaign_name, mc.campaign_type, mc.budget, mc.start_date, mc.end_date
),
customer_first_purchase as(
	select
		c.cust_id,
		min(o.order_date) as first_purchase_date
	from customers c
    inner join orders o on c.cust_id = o.cust_id
    where o.order_status in ('delivered', 'shipped')
    group by c.cust_id
),
new_customers as (
    select
        mc.campaign_id,
        count(distinct cfp.cust_id) as new_customers
    from marketing_campaigns mc
    left join customer_campaigns cc on mc.campaign_id = cc.campaign_id
    left join customers c on cc.cust_id = c.cust_id
    left join customer_first_purchase cfp on c.cust_id = cfp.cust_id
        and cfp.first_purchase_date between mc.start_date and mc.end_date
    group by mc.campaign_id
)
select
    cp.campaign_name,
    cp.campaign_type,
    cp.budget,
    cp.revenue,
    cp.profit,
	round(100.0 * cp.profit / nullif(cp.budget, 0), 2) as roi_percent,
    round(100.0 * cp.customers_converted / nullif(cp.customers_reached, 0), 2) as conversion_rate,
    round(100.0 * cp.customers_responded / nullif(cp.customers_reached, 0), 2) as response_rate,
    round(100.0 * cp.customers_converted / nullif(cp.customers_clicked, 0), 2) as purchase_from_click_rate,
	round(100.0 * nc.new_customers / nullif(cp.customers_converted, 0), 2) as new_customer_percent,
    round(100.0 * cp.repeat_buyers / nullif(cp.customers_converted, 0), 2) as repeat_rate,
    round(cp.budget / nullif(cp.customers_converted, 0), 2) as cpa,
    round(
		(round(100.0 * cp.profit / nullif(cp.budget, 0), 2)* 0.25) +
        (round(100* cp.customers_converted / nullif(cp.customers_reached, 0), 2) * 0.20) +
        (round(100.0 * cp.repeat_buyers / nullif(cp.customers_converted, 0), 2) * 0.20) +
        (round(100.0 * nc.new_customers / nullif(cp.customers_converted, 0), 2) * 0.15) +
        (round(100.0 * cp.customers_responded / nullif(cp.customers_reached, 0), 2) * 0.10) +
        (case when cp.profit > 0 then 10 else 0 end * 0.10)
    ,2) as combined_score,
    rank() over(order by 
        (round(100.0 * cp.profit / nullif(cp.budget, 0), 2) * 0.25) +
        (round(100.0 * cp.customers_converted / nullif(cp.customers_reached, 0), 2) * 0.20) +
        (round(100.0 * cp.repeat_buyers / nullif(cp.customers_converted, 0), 2) * 0.20) +
        (round(100.0 * nc.new_customers / nullif(cp.customers_converted, 0), 2) * 0.15) +
        (round(100.0 * cp.customers_responded / nullif(cp.customers_reached, 0), 2) * 0.10) +
        (case when cp.profit > 0 then 10 else 0 end * 0.10)
    desc) as campaign_rank
from campaign_performance cp
left join new_customers nc on cp.campaign_id = nc.campaign_id
order by campaign_rank;