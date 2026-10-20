USE customer_intelligence_db;

-- --------------------------------------------- funtions
delimiter //

create function fn_profit(p_order_id int)
returns decimal(10,2)
deterministic
begin
    declare v_profit decimal(10,2);
    
    select coalesce(round(sum(oi.quantity * oi.selling_price) - sum(oi.quantity * p.cost_price), 2), 0)
    into v_profit
    from order_items oi
    join products p on oi.prod_id = p.prod_id
    where oi.order_id = p_order_id;
    
    return v_profit;
end //

delimiter ;

-- ---------------------------------------------------2
delimiter //

create function fn_order_value(o_order_id int)
returns decimal(10,5)
deterministic
begin
	declare v_value decimal(10,2);
    
    select coalesce(round(sum(oi.quantity * oi.selling_price),2),0)
    into v_value
    from order_items oi
    where oi.order_id = o_order_id;
    return v_value;
end //
delimiter ;

-- -------------------------------------------------3
delimiter //

create function fn_customer_revenue(c_cust_id int)
returns decimal(10,2)
deterministic
begin
    declare c_revenue decimal(10,2);
    
    select coalesce(round(sum(oi.quantity * oi.selling_price), 2), 0)
    into c_revenue
    from order_items oi
    inner join orders o on oi.order_id = o.order_id  
    where o.cust_id = c_cust_id;    
    return c_revenue;
end //

delimiter ;
-- -------------------------------------------------4
delimiter //

create function fn_customer_profit(c_cust_id int)
returns decimal(10,2)
deterministic
begin
    declare c_profit decimal(10,2);
    
    select coalesce(round(sum(oi.quantity * oi.selling_price) - sum(oi.quantity * p.cost_price), 2), 0)
    into c_profit
    from order_items oi
    inner join orders o on oi.order_id = o.order_id   
    inner join products p on p.prod_id = oi.prod_id
    where o.cust_id = c_cust_id;                  
    return c_profit;
end //

delimiter ;

-- ----------------------------------------------------5
delimiter //
create function fn_profit_margin(o_order_id int)
returns decimal(10,2)
deterministic
begin
	declare o_margin decimal(10,2);
    with cust_revenue as(
		select
			round(sum(oi.quantity * oi.selling_price),2) as revenue,
            round(sum(oi.quantity * oi.selling_price) - sum(oi.quantity * p.cost_price),2) as profit
		from order_items oi
        join products p on oi.prod_id = p.prod_id
		)
        select
			case
				when revenue = 0 then 0
				else round((profit/ revenue)*100 ,2)
			end
		from cust_revenue
        into o_margin;
        return o_margin;
end //
delimiter ;

-- ----------------------------------------------------6
delimiter //

create function fn_customer_clv(c_cust_id int)
returns decimal(10,2)
deterministic
begin
	declare c_clv decimal(10,2);
    with order_metrics as(
    select 
		round(sum(oi.quantity * oi.selling_price),2) as total_revenue,
        count(distinct o.order_id) as total_orders,
        max(o.order_date) as last_purchase_date,
        min(o.order_date) as first_purchase_date,
        round(datediff(max(o.order_date),min(o.order_date))/ 30 ,2) as customer_lifespan_months
	from orders o
    join order_items oi on o.order_id = oi.order_id
    where o.order_status in ('delivered', 'shipped') and o.cust_id = c_cust_id
	)
    select
		case when customer_lifespan_months then total_revenue
		else round((total_revenue/ total_orders)*(total_orders / customer_lifespan_months) *(customer_lifespan_months),2) 
        end
	from order_metrics 

	into c_clv;
    return c_clv;
end //
delimiter ;

-- ---------------------------------------------7
delimiter //

create function fn_customer_segment(c_cust_id int)
returns varchar(50)
deterministic
begin
	declare segment varchar(50);
    with cust_revenue as (
    select
		c.cust_id,
        c.cust_name,
        round(sum(oi.quantity * oi.selling_price),2) as revenue
        from customers c
        join orders o on c.cust_id = o.cust_id
        join order_items oi on oi.order_id = o.order_id
        where o.order_status in ('delivered', 'shipped') and o.cust_id = c_cust_id
        group by c.cust_id
	)
    select
		case
			when revenue >= 500000 then 'VIP'
            when revenue >= 200000 then 'Gold'
            when revenue >= 100000 then 'Silver'
            else 'Bronze'
		end
        from cust_revenue
        into segment;
        return segment;
end //
delimiter ;

-- --------------------------------------8
delimiter //

create function fn_purchase_frequency(c_cust_id int)
returns decimal(10,2)
deterministic
begin
    declare freq decimal(10,2);
    
    with customer_orders as (
        select
            count(distinct o.order_id) as total_orders,
            min(o.order_date) as first_order,
            max(o.order_date) as last_order
        from orders o
        where o.cust_id = c_cust_id
          and o.order_status in ('delivered', 'shipped')
    )
    select
        case
            when total_orders <= 1 then 0
            else round(datediff(last_order, first_order) / (total_orders - 1), 0)
        end
    into freq
    from customer_orders;
    
    return freq;
end //

delimiter ;

-- -----------------------------------------------9
delimiter //

create function fn_customer_age(p_join_date date)
returns decimal(10,2)
deterministic
begin
    declare age_months decimal(10,2);
    
    set age_months = round(datediff(curdate(), p_join_date) / 30.0, 2);
    
    return age_months;
end //

delimiter ;

-- ---------------------------------------------------10
delimiter //

create function fn_customer_status(c_cust_id int)
returns varchar(50)
deterministic
begin
    declare cust_status varchar(50);
    declare last_order_date date;
    declare first_order_date date;
    declare days_since_last int;
    declare total_orders int;
    
    select
        max(order_date),
        min(order_date),
        count(distinct order_id)
    into last_order_date, first_order_date, total_orders
    from orders
    where cust_id = c_cust_id
      and order_status in ('delivered', 'shipped');
    
    if last_order_date is null then
        set cust_status = 'inactive';
    else
        set days_since_last = datediff(curdate(), last_order_date);
        
        if days_since_last <= 30 then
            set cust_status = 'active';
        elseif days_since_last <= 60 then
            set cust_status = 'engaged';
        elseif days_since_last <= 90 then
            set cust_status = 'at risk';
        elseif days_since_last <= 180 then
            set cust_status = 'dormant';
        else
            set cust_status = 'churned';
        end if;
        
        if total_orders = 1 and days_since_last <= 30 then
            set cust_status = 'new';
        end if;
    end if;
    
    return cust_status;
end //

delimiter ;

-- ----------------------------------------11
delimiter //

create function fn_product_profit(p_prod_id int)
returns decimal(10,2)
deterministic
begin
    declare total_profit decimal(10,2);
    
    select coalesce(round(sum(oi.quantity * oi.selling_price) - sum(oi.quantity * pr.cost_price), 2), 0)
    into total_profit
    from order_items oi
    join orders o on oi.order_id = o.order_id
    join products pr on oi.prod_id = pr.prod_id
    where oi.prod_id = p_prod_id
      and o.order_status in ('delivered', 'shipped');
    
    return total_profit;
end //

delimiter ;

-- -----------------------------------------------12
delimiter //

create function fn_product_profit(p_prod_id int)
returns decimal(10,2)
deterministic
begin
    declare total_profit decimal(10,2);
    
    select coalesce(round(sum(oi.quantity * oi.selling_price) - sum(oi.quantity * pr.cost_price), 2), 0)
    into total_profit
    from order_items oi
    join orders o on oi.order_id = o.order_id
    join products pr on oi.prod_id = pr.prod_id
    where oi.prod_id = p_prod_id
      and o.order_status in ('delivered', 'shipped');
    
    return total_profit;
end //

delimiter ;

delimiter //

create function fn_inventory_value(p_prod_id int)
returns decimal(10,2)
deterministic
begin
    declare inv_value decimal(10,2);
    
    select coalesce(round(stock * price, 2), 0)
    into inv_value
    from products
    where prod_id = p_prod_id;
    
    return inv_value;
end //

delimiter ;

delimiter //

create function fn_product_margin(p_prod_id int)
returns decimal(10,2)
deterministic
begin
    declare revenue decimal(10,2);
    declare cost decimal(10,2);
    declare margin decimal(10,2);
    
    select
        coalesce(round(sum(oi.quantity * oi.selling_price), 2), 0),
        coalesce(round(sum(oi.quantity * pr.cost_price), 2), 0)
    into revenue, cost
    from order_items oi
    join orders o on oi.order_id = o.order_id
    join products pr on oi.prod_id = pr.prod_id
    where oi.prod_id = p_prod_id
      and o.order_status in ('delivered', 'shipped');
    
    if revenue = 0 then
        set margin = 0;
    else
        set margin = round(100.0 * (revenue - cost) / revenue, 2);
    end if;
    
    return margin;
end //

delimiter ;

delimiter //

create function fn_stock_status(p_prod_id int)
returns varchar(20)
deterministic
begin
    declare current_stock int;
    declare status varchar(20);
    
    select coalesce(stock, 0)
    into current_stock
    from products
    where prod_id = p_prod_id;
    
    if current_stock = 0 then
        set status = 'out of stock';
    elseif current_stock <= 10 then
        set status = 'critical';
    elseif current_stock <= 25 then
        set status = 'low stock';
    elseif current_stock <= 50 then
        set status = 'medium stock';
    else
        set status = 'in stock';
    end if;
    
    return status;
end //

delimiter ;

delimiter //

create function fn_total_units_sold(p_prod_id int)
returns int
deterministic
begin
    declare total_units int;
    
    select coalesce(sum(oi.quantity), 0)
    into total_units
    from order_items oi
    join orders o on oi.order_id = o.order_id
    where oi.prod_id = p_prod_id
      and o.order_status in ('delivered', 'shipped');
    
    return total_units;
end //

delimiter ; 