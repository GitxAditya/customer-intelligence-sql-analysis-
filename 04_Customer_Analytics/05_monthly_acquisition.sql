with first_purchase as(
	select
		c.cust_id,
        c.cust_name,
        min(o.order_date) as first_order_date,
        date_format(min(o.order_date), "%Y-%m-01") as cohort_month,
        date_format(min(o.order_date), "%M %Y") as month_name
	from customers c
    inner join orders o on o.cust_id = c.cust_id
    inner join payments p on p.order_id = o.order_id
    where o.order_status in ('Delivered', 'Shipped')
		and p.payment_status = "Success"
	group by c.cust_id, c.cust_name
),
monthly_aquistion as (
	select
		cohort_month,
        count(*) as new_customers
	from first_purchase
    group by cohort_month
)
select
	date_format(cohort_month,"%M %Y") as month,
    new_customers,
    sum(new_customers) over(order by cohort_month) as runing_total,
    round(
    100* (new_customers - lag(new_customers) over(order by cohort_month)) /
    nullif(lag(new_customers) over(order by cohort_month),0),2
    ) as growth_percentage,
    round(
    100 *new_customers/sum(new_customers) over(),2
    ) as contribution_percentage
from monthly_aquistion
order by cohort_month;