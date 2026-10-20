use customer_intelligence_db;

-- -------------------------------------------------------Ques29
with product_sales as(
	select
		p.prod_id,
        p.prod_name,
        p.category,
        p.brand,
        p.stock as current_stock,
        round(p.price * p.stock, 2) as inventory_value,
        coalesce(sum(oi.quantity),0) as units_sold,
        coalesce(max(o.order_date),0) as last_sale_date,
        datediff(curdate(), coalesce(max(o.order_date), curdate())) as days_since_last_sale
	from products p
    left join order_items oi on oi.prod_id = p.prod_id
    left join orders o on o.order_id = oi.order_id
		and o.order_status IN ('Delivered', 'Shipped')
    left join payments pm on o.order_id = pm.order_id
		and pm.payment_status = 'Success'
	group by p.prod_id, p.prod_name, p.category, p.brand, p.stock
)   
select
	prod_id,
    prod_name,
    category,
    brand,
    current_stock,
    inventory_value,
    units_sold,
    coalesce(last_sale_date, "Never_sold") as last_sale_date,
    days_since_last_sale,
    case
		when units_sold = 0 then "No sold"
        when days_since_last_sale >= 180 then "Very slow"
        when days_since_last_sale >= 90 then "Slow"
        when days_since_last_sale >=30 then "Moderate"
        else "Fast Moving"
	end as sale_status,
   case
		when units_sold = 0 then "Remove from Inventory"
        when days_since_last_sale >= 180 and current_stock > 0 then "Heavy Discount or Bundle"
        when days_since_last_sale >= 90 and current_stock > 10 then " Discount to Clear"
        when days_since_last_sale >=30 and current_stock > 5 then "Promote Actively"
        else "Maintain Stock"
	end as recommendation
from  product_sales
where current_stock > 0
	and (units_sold = 0 or days_since_last_sale >= 30)
order by days_since_last_sale desc