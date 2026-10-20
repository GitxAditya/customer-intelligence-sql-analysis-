USE customer_intelligence_db;

-- ----------------------------------------------------Store procedure
delimiter //
create procedure sp_create_order(
	in p_cust_id int,
    in p_order_date date,
    in p_order_status varchar(50),
    in p_prod_id int,
    in p_quantity int)
    
    begin 
		declare v_customer_exists int;
		declare v_product_exists int;
		declare v_current_stock int;
		declare v_order_id int;
		declare v_price decimal(10,2);
	
    select count(*) into v_customer_exists
    from customers
    
    if v_customer_exists = 0 then
        signal sqlstate '45000'
        set message_text = 'Customer not found';
    end if;
    
    select stock, price into v_current_stock, v_price
    from products
    where prod_id = p_prod_id;
    
    if v_current_stock is null then
        signal sqlstate '45000'
        set message_text = 'Product not found';
    end if;
    
    if v_current_stock < p_quantity then
        signal sqlstate '45000'
        set message_text = concat('Insufficient stock. Available: ', v_current_stock);
    end if;
    
    insert into orders (cust_id, order_date, order_status)
    values (p_cust_id, p_order_date, p_order_status);
    
    set v_order_id = last_insert_id();
    
    insert into order_items (order_id, prod_id, quantity, selling_price)
    values (v_order_id, p_prod_id, p_quantity, v_price);
    
    update products
    set stock = stock - p_quantity
    where prod_id = p_prod_id;
    
    select v_order_id as new_order_id, 'Order created successfully' as message;
delimiter ;

-- ------------------------------------- 2
delimiter //
create procedure sp_create_order_safe(
	  in p_cust_id int,
    in p_order_date date,
    in p_order_status varchar(50),
    in p_prod_id int,
    in p_quantity int
)
begin
    declare v_customer_exists int;
    declare v_product_exists int;
    declare v_current_stock int;
    declare v_order_id int;
    declare v_price decimal(10,2);
    
    declare exit handler for sqlexception
    begin
		rollback;
        resignal;
	end;
    select count(*) into v_customer_exists
    from customers
    where cust_id = p_cust_id;
    
    if v_customer_exists = 0 then
     signal sqlstate '45000'
     set message_text = 'Customer not found';
    end if;
    
    select stock, price into v_current_stock, v_price
    from products
    where prod_id = p_prod_id;
    
    if v_current_stock is null then
        signal sqlstate '45000'
        set message_text = 'Product not found';
    end if;
    
    if v_current_stock < p_quantity then
        signal sqlstate '45000'
        set message_text = 'Insufficient stock. Available: ';
    end if;
    start transaction;
    
	insert into orders (cust_id, order_date, order_status)
    values (p_cust_id, p_order_date, p_order_status);
    
    set v_order_id = last_insert_id();
    
    insert into order_items (order_id, prod_id, quantity, selling_price)
    values (v_order_id, p_prod_id, p_quantity, v_price);
    
    update products
    set stock = stock - p_quantity
    where prod_id = p_prod_id;
    
    commit;
    select v_order_id as new_order_id, 'Order created successfully' as message;

end //
delimiter ;

-- ------------------------------------------------------3
delimiter //

create procedure sp_customer_summary(
    in p_cust_id int
)
begin
    if not exists (select 1 from customers where cust_id = p_cust_id) then
        signal sqlstate '45000'
        set message_text = 'Customer not found';
    end if;

    select
        c.cust_id,
        c.cust_name,
        c.city,
        c.state,
        c.signup_date,
        coalesce(count(distinct o.order_id), 0) as total_orders,
        coalesce(sum(oi.quantity), 0) as total_units_purchased,
        coalesce(round(sum(oi.quantity * oi.selling_price), 2), 0) as total_revenue,
        coalesce(round(sum(oi.quantity * oi.selling_price) - sum(oi.quantity * pr.cost_price), 2), 0) as total_profit,
        case
            when count(distinct o.order_id) = 0 then 0
            else round(sum(oi.quantity * oi.selling_price) / count(distinct o.order_id), 2)
        end as avg_order_value,
        min(o.order_date) as first_purchase_date,
        max(o.order_date) as last_purchase_date,
        datediff(curdate(), max(o.order_date)) as days_since_last_purchase
    from customers c
    left join orders o on c.cust_id = o.cust_id
        and o.order_status in ('delivered', 'shipped')
    left join order_items oi on o.order_id = oi.order_id
    left join products pr on oi.prod_id = pr.prod_id
    where c.cust_id = p_cust_id
    group by c.cust_id, c.cust_name, c.city, c.state, c.signup_date;

end //

delimiter ;

-- -------------------------------------------------------4
delimiter //

create procedure sp_restock_product(
    in p_prod_id int,
    in p_quantity int
)
begin
    declare v_old_stock int;
    declare v_product_name varchar(100);
    
    select stock, prod_name into v_old_stock, v_product_name
    from products
    where prod_id = p_prod_id;
    
    if v_old_stock is null then
        signal sqlstate '45000'
        set message_text = 'Product not found';
    end if;
    
    if p_quantity <= 0 then
        signal sqlstate '45000'
        set message_text = 'Restock quantity must be greater than 0';
    end if;
    
    update products
    set stock = stock + p_quantity
    where prod_id = p_prod_id;
    
    insert into inventory_audit (prod_id, old_stock, new_stock, action, changed_at)
    values (p_prod_id, v_old_stock, v_old_stock + p_quantity, 'restock', now());
    
    select
        p_prod_id as product_id,
        v_product_name as product_name,
        v_old_stock as old_stock,
        p_quantity as added_quantity,
        v_old_stock + p_quantity as new_stock,
        'Product restocked successfully' as message;
    
end //

delimiter ;

 -- ----------------------------------------------------5
delimiter //

create procedure sp_monthly_executive_report(
    in p_year int,
    in p_month int
)
begin
    declare v_total_revenue decimal(10,2);
    declare v_total_orders int;
    declare v_total_customers int;
    declare v_avg_order_value decimal(10,2);
    declare v_total_profit decimal(10,2);
    declare v_profit_margin decimal(10,2);
    declare v_return_rate decimal(10,2);
    declare v_refund_rate decimal(10,2);
    declare v_net_revenue decimal(10,2);
    declare v_net_profit decimal(10,2);

    if p_month < 1 or p_month > 12 then
        signal sqlstate '45000'
        set message_text = 'Invalid month. Must be between 1 and 12';
    end if;

    if p_year < 2000 or p_year > year(curdate()) then
        signal sqlstate '45000'
        set message_text = 'Invalid year';
    end if;

    select
        coalesce(round(sum(oi.quantity * oi.selling_price), 2), 0),
        count(distinct o.order_id),
        count(distinct o.cust_id),
        round(sum(oi.quantity * oi.selling_price) / nullif(count(distinct o.order_id), 0), 2),
        coalesce(round(sum(oi.quantity * oi.selling_price) - sum(oi.quantity * pr.cost_price), 2), 0),
        coalesce(round((sum(oi.quantity * oi.selling_price) - sum(oi.quantity * pr.cost_price)) * 100.0 / nullif(sum(oi.quantity * oi.selling_price), 0), 2), 0)
    into v_total_revenue, v_total_orders, v_total_customers, v_avg_order_value, v_total_profit, v_profit_margin
    from orders o
    join order_items oi on o.order_id = oi.order_id
    join products pr on oi.prod_id = pr.prod_id
    where o.order_status in ('delivered', 'shipped')
      and year(o.order_date) = p_year
      and month(o.order_date) = p_month;

    select
        coalesce(round(100.0 * count(distinct r.return_id) / nullif(count(distinct o.order_id), 0), 2), 0)
    into v_return_rate
    from orders o
    left join returns r on o.order_id = r.order_id
    where o.order_status in ('delivered', 'shipped')
      and year(o.order_date) = p_year
      and month(o.order_date) = p_month;

    select
        coalesce(round(100.0 * count(distinct case when pm.payment_status = 'refunded' then pm.payment_id end) / nullif(count(distinct o.order_id), 0), 2), 0)
    into v_refund_rate
    from orders o
    left join payments pm on o.order_id = pm.order_id
    where o.order_status in ('delivered', 'shipped')
      and year(o.order_date) = p_year
      and month(o.order_date) = p_month;

    select
        coalesce(round(sum(oi.quantity * oi.selling_price), 2), 0),
        coalesce(round(sum(oi.quantity * oi.selling_price) - sum(oi.quantity * pr.cost_price), 2), 0)
    into v_net_revenue, v_net_profit
    from orders o
    join order_items oi on o.order_id = oi.order_id
    join products pr on oi.prod_id = pr.prod_id
    where o.order_status in ('delivered', 'shipped')
      and year(o.order_date) = p_year
      and month(o.order_date) = p_month
      and o.order_id not in (
          select distinct r.order_id
          from returns r
      )
      and o.order_id not in (
          select distinct pm.order_id
          from payments pm
          where pm.payment_status = 'refunded'
      );

    select
        p_year as report_year,
        p_month as report_month,
        date_format(concat(p_year, '-', p_month, '-01'), '%M %Y') as month_name,
        v_total_revenue as total_revenue,
        v_total_orders as total_orders,
        v_total_customers as total_customers,
        v_avg_order_value as avg_order_value,
        v_total_profit as total_profit,
        v_profit_margin as profit_margin_percent,
        v_return_rate as return_rate_percent,
        v_refund_rate as refund_rate_percent,
        v_net_revenue as net_revenue,
        v_net_profit as net_profit;

end //

delimiter ;
