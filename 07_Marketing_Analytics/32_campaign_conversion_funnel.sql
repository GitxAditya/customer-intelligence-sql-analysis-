use customer_intelligence_db;

-- --------------------------------------------------Ques 32
with campaign_conversion as(
	select
		mc.campaign_id,
        mc.campaign_name,
        mc.campaign_type,
        mc.budget,
        mc.start_date,
        mc.end_date,
        count(distinct cc.cust_id) as customers_targeted,
        count(distinct case when cc.campaign_status = 'Clicked' then cc.cust_id end) as customers_clicked,
        count(distinct case when cc.campaign_status = 'Purchased' then cc.cust_id end) as customers_purchased,
        count(distinct case when cc.campaign_status = 'Opened' then cc.cust_id end) as customers_opened
	from marketing_campaigns mc
    left join customer_campaigns cc on mc.campaign_id = cc.campaign_id
    group by mc.campaign_id, mc.campaign_name, mc.campaign_type, mc.budget, mc.start_date, mc.end_date
),
campaign_metrics as(
	select
		*,
		round(100* customers_opened/ nullif(customers_targeted,0),2) as open_rate,
		round(100* customers_clicked/ nullif(customers_opened,0),2) as click_to_open_rate,
		round(100* customers_purchased/ nullif(customers_clicked,0),2) as purchase_from_click_rate,
		round(100* customers_purchased / nullif(customers_targeted,0),2) as conversion_rate
	from campaign_conversion
)
select
	rank() over(order by conversion_rate desc) as conversion_rank,
    campaign_name,
    campaign_type,
    budget,
    customers_targeted,
    customers_opened,
    customers_clicked,
    customers_purchased,
    case
		when conversion_rate >= 10 then "Execellent"
        when conversion_rate >= 5 then "Good"
        when conversion_rate >= 2 then "Average"
        else "Poor"
	end as conversion_category
from campaign_metrics
where customers_targeted > 0
order by conversion_rank