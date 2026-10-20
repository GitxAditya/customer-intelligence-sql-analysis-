USE customer_intelligence_db;
with rfm_data as (
	select
		c.cust_id,
		c.cust_name,
        c.city,
        c.state,
        datediff(curdate(), max(o.order_date)) as recency_days,
        count(distinct o.order_id) as frequency,
        round(sum(oi.quantity * oi.selling_price),2) as monetary,
        max(o.order_date) as last_order_date,
        min(o.order_date) as first_order_date
	from customers c
    inner join orders o on c.cust_id = o.cust_id
    inner join order_items oi on o.order_id = oi.order_id
    inner join payments p on p.order_id = o.order_id
    where o.order_status in ('Delivered', 'Shipped')
		and p.payment_status = "Success"
	group by c.cust_id, c.cust_name, c.city, c.state
),
rfm_scores as(
	select
		cust_id,
        cust_name,
        city,
        state,
        recency_days,
        frequency,
        monetary,
        last_order_date,
        first_order_date,
        case
			WHEN recency_days <= 30 THEN 5
            WHEN recency_days <= 60 THEN 4
            WHEN recency_days <= 90 THEN 3
            WHEN recency_days <= 180 THEN 2
            ELSE 1
        END AS r_score,
        CASE
			 WHEN frequency >= 10 THEN 5
            WHEN frequency >= 7 THEN 4
            WHEN frequency >= 4 THEN 3
            WHEN frequency >= 2 THEN 2
            ELSE 1
        END AS f_score,
        CASE
			WHEN monetary >= 500000 THEN 5
            WHEN monetary >= 200000 THEN 4
            WHEN monetary >= 100000 THEN 3
            WHEN monetary >= 50000 THEN 2
            ELSE 1
        END AS m_score
    from rfm_data
),
rfm_combined as(
	select
		cust_id,
        cust_name,
        city,
        state,
        recency_days,
        frequency,
        monetary,
        last_order_date,
        first_order_date,
        r_score,
        f_score,
        m_score,
        CONCAT(r_score, f_score, m_score) AS rfm_score,
        (r_score + f_score + m_score) as rfm_total
	from rfm_scores
)
select
	cust_id,
        cust_name,
        city,
        state,
        recency_days ,
        frequency,
        monetary,
        last_order_date,
        first_order_date,
        r_score,
        f_score,
        m_score,
        rfm_score,
        rfm_total,
        case
			when r_score >= 4 and f_score >= 4 and m_score >= 4 then 'VIP'
			when r_score >= 3 and f_score >= 3 and m_score >= 3 then 'Loyal'
			when r_score >= 2 and f_score >= 2 and m_score >= 2 then 'Regular'
			when r_score <= 2 and (f_score >= 3 or m_score >= 3) then 'At Risk'
			when r_score <= 2 and f_score <= 2 and m_score <= 2 then 'Lost'
			when frequency = 1 and r_score >= 3 then 'New'
			else 'Other'
		end as customer_segment
	from rfm_combined
    order by rfm_total DESC, monetary DESC;