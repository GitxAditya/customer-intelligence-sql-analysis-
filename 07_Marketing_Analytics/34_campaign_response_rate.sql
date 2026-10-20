use customer_intelligence_db;

-- -----------------------------------------------------Ques 34
with campaign_conversion as(
	select
		mc.campaign_id,
        mc.campaign_name,
        mc.campaign_type,
        mc.budget,
        mc.start_date,
        mc.end_date,
        count(distinct cc.cust_id) as customers_sent,
        count(distinct case when cc.campaign_status in ('Opened', 'Clicked', 'Purchased') then cc.cust_id end) as customers_responded,
        count(distinct case when cc.campaign_status = 'Clicked' then cc.cust_id end) as customers_clicked,
        count(distinct case when cc.campaign_status = 'Purchased' then cc.cust_id end) as customers_purchased,
        count(distinct case when cc.campaign_status = 'Opened' then cc.cust_id end) as customers_opened
	from marketing_campaigns mc
    left join customer_campaigns cc on mc.campaign_id = cc.campaign_id
    group by mc.campaign_id, mc.campaign_name, mc.campaign_type, mc.budget, mc.start_date, mc.end_date
),
response as(
	select
		*,
		round(100* customers_responded/nullif(customers_sent, 0),2) as response_rate
	from campaign_conversion 
)
select
	rank() over(order by response_rate desc) as response_rank,
	campaign_name,
    campaign_type,
    budget,
    customers_sent,
    customers_opened,
    customers_clicked,
    customers_purchased,
    customers_responded,
    case
		when response_rate >= 50 then "Excellent Response"
        when response_rate >= 30 then "Good Response"
        when response_rate >= 15 then "Average Response"
        else "Low Response"
	end as response_category
from response
where customers_sent > 0
order by response_rank;