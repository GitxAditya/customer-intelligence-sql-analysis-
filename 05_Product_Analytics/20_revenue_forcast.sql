use customer_intelligence_db;

-- ---------------------------------------------Ques 20
with monthly_revenue as(
	select
		date_format(o.order_date,"%Y-%m-01") as month_date,
        date_format(o.order_date,"%M %Y") as month,
        coalesce(round(sum(oi.quantity*oi.selling_price),2),0) as revenue
	from orders o
    inner join order_items oi on o.order_id = oi.order_id
    inner join payments p on o.order_id = p.order_id
    where o.order_status in ('Delivered', 'Shipped')
        and p.payment_status = 'Success'
	group by date_format(o.order_date,"%Y-%m-01"),
        date_format(o.order_date,"%M %Y")
),
moving_avg as (
	select
        month_date,
        month,
        revenue,
        round(avg(revenue) over(order by month_date rows between 2 preceding and 1 preceding), 2) as three_month_moving_avg,
        round(avg(revenue) over(order by month_date rows between 5 preceding and 1 preceding), 2) as six_month_moving_avg,
        round(avg(revenue) over(order by month_date rows between 2 preceding and current row), 2) as three_month_rolling_avg,
        round(sum(revenue) over(order by month_date rows between 2 preceding and 1 preceding)/3 ,2) as forecast_3month_avg,
        round(lag(revenue,1) over(order by month_date)* 1.05,2) as  forecast_5_percent_growth
	from monthly_revenue
)
select 
	month,
    revenue,
    three_month_moving_avg,
    six_month_moving_avg,
    three_month_rolling_avg,
    forecast_3month_avg AS forecast_next_month,
    forecast_5_percent_growth AS forecast_alternative
from moving_avg
order by month_date;