use customer_intelligence_db;

-- --------------------------------------------------------Ques 25
with wishlist_conversion as(
	select
		p.prod_id,
        p.prod_name,
        p.category,
        p.brand,
        coalesce(count(distinct w.wishlist_id),0) as wishlist_count,
        coalesce(count(distinct o.order_id),0) as purchase_count
	from products p
    left join wishlist w on p.prod_id = w.prod_id
    left join order_items oi on p.prod_id = oi.prod_id
    left join orders o on oi.order_id = o.order_id
        and o.order_status in ('Delivered', 'Shipped')
    left join payments pm on o.order_id = pm.order_id
        and pm.payment_status = 'Success'
    group by p.prod_id, p.prod_name, p.category, p.brand
)
select
	prod_name,
    category,
    brand,
    wishlist_count,
    purchase_count,
	case
		when wishlist_count = 0 then 0
        else round(100* purchase_count/wishlist_count, 2)
	end as conversion_rate_percent,
    case
        when wishlist_count = 0 THEN 'No Wishlist Data'
        when (purchase_count * 1.0 / wishlist_count) >= 0.5 THEN 'Excellent'
        when (purchase_count * 1.0 / wishlist_count) >= 0.3 THEN 'Good'
        when (purchase_count * 1.0 / wishlist_count) >= 0.1 THEN 'Average'
        else 'Poor'
    end as conversion_category,
    rank() over(order by (100* purchase_count / wishlist_count) desc) as conversion_rank
    from wishlist_conversion
    where wishlist_count > 0
    order by conversion_rank;