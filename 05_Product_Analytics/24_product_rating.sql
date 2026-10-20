use customer_intelligence_db;

-- ----------------------------------------------- Ques 24
with product_rating as(
	select
		p.prod_id,
        p.prod_name,
        p.category,
        p.brand,
        coalesce(count(r.review_id),0) as total_reviews,
        coalesce(round(avg(r.rating),2),0) as avg_rating,
        coalesce(round(100* sum(case when r.rating =5 then 1 else 0 end)/ nullif(count(r.review_id),0),2),0) as five_star_percent,
        coalesce(round(100* sum(case when r.rating >= 4 then 1 else 0 end)/ nullif(count(r.review_id),0),2),0) as positive_review_percentage,
		coalesce(round(sum(oi.quantity*oi.selling_price),2),0) as revenue
	from products p
    left join reviews r on p.prod_id = r.prod_id
    left join order_items oi on p.prod_id = oi.prod_id
    left join orders o on o.order_id = oi.order_id
    left join payments pm on o.order_id = pm.order_id
    where o.order_status in ('Delivered', 'Shipped')
        and pm.payment_status = 'Success'
	group by p.prod_id, p.prod_name, p.category, p.brand
)
select
	rank() over(order by avg_rating desc, total_reviews desc) as rating_rank,
	prod_id,
	prod_name,
	category,
	brand,
    total_reviews,
    avg_rating,
    five_star_percent,
    positive_review_percentage,
    revenue,
	case
        when total_reviews = 0 then 'No Reviews'
        when avg_rating >= 4.5 and total_reviews >= 10 then 'Top Rated'
        when avg_rating >= 4.0 then 'Good'
        when avg_rating >= 3.0 then 'Average'
        when avg_rating > 0 then 'Poor'
        else 'No Reviews'
    end as rating_category
from product_rating
order by rating_rank;