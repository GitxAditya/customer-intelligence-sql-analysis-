use customer_intelligence_db;

-- ------------------------------------------------------------------Ques 38
with funnel_data as(
	select
		mc.campaign_id,
        mc.campaign_name,
        count(distinct cc.cust_id) as sent,
        count(distinct case when cc.campaign_status in ('Opened', 'Clicked', 'Purchased') then cc.cust_id end) as opened,
        count(distinct case when cc.campaign_status in ('Clicked', 'Purchased') then cc.cust_id end) as clicked,
        count(distinct case when cc.campaign_status  ='Purchased' then cc.cust_id end) as purchased,
        count(distinct case
            when cc.campaign_status  ='Purchased' and
            exists (
				select 1
                from orders o2
                where cc.cust_id = o2.cust_id
                and o2.order_date > (
					select min(o.order_date) 
                    from orders o 
                    where o.cust_id = cc.cust_id and
                    o.order_date between  mc.start_date and mc.end_date)
            ) then cc.cust_id
            end) as repeat_purchased
    from marketing_campaigns mc
    left join customer_campaigns cc ON mc.campaign_id = cc.campaign_id
    group by mc.campaign_id, mc.campaign_name
)
select
	"Sent" as funnel_stage,
    sum(sent) as users,
    null as conversion_rate,  
    null as drop_off
from funnel_data
union all
select
	"Opened",
    sum(opened),
    round(100* sum(opened)/ nullif(sum(sent),0),2) as conversion_rate,
    round(100* (sum(sent) - sum(opened))/ nullif(sum(sent),0),2) as drop_off
from funnel_data
union all
select
	"Clicked",
    sum(clicked),
    round(100* sum(clicked)/ nullif(sum(sent),0),2) as conversion_rate,
    round(100* (sum(opened)- sum(clicked))/ nullif(sum(opened),0),2) as drop_off
from funnel_data
union all
select
	"Purchased",
    sum(purchased),
    round(100* sum(purchased)/nullif(sum(sent),0),2) as conversion_rate,
    round(100* (sum(clicked)- sum(purchased))/ nullif(sum(clicked),0),2) as drop_off
from funnel_data
union all
select
	"Repeat Purchased",
    sum(repeat_purchased),
    round(100* sum(repeat_purchased)/nullif(sum(sent),0),2) as conversion_rate,
    round(100* (sum(purchased)- sum(repeat_purchased))/nullif(sum(purchased),0),2) as drop_off
from funnel_data