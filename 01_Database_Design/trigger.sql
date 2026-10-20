USE customer_intelligence_db;

-- ----------------------------------------Trigger
delimiter //
create trigger before_order_insert
before insert on orders
for each row
begin
	if new.order_date > curdate() then
		signal sqlstate '45000'
        set message_text = "Order date cannot be in the future";
	end if;
    if new.order_status is null or trim(new.order_status) = ' ' then
    signal sqlstate '45000'
    set message_text = 'Order status cannot be null or empty';
    end if;
    if new.order_status not in ('Pending', 'Shipped', 'Delivered', 'Cancelled', 'Returned') then
        signal sqlstate '45000'
        set message_text = 'Invalid order status. Must be Pending, Shipped, Delivered, Cancelled, or Returned';
    end if;
end //

delimiter ;

-- ----------------------------------------------------2
delimiter //
create trigger before_order_item_insert
before insert on order_items
for each row
begin
	declare v_current_stock int;
    select stock into v_current_stock
    from products
    where prod_id = new.prod_id;
    
    if new.quantity <= 0 then
		signal sqlstate '45000'
        set message_text = 'Quantity must be greater than 0';
    end if;
    if v_current_stock < new.quantity then
        signal sqlstate '45000'
        set message_text = 'Not enough stock. Available: ';
    end if;
end //

delimiter ;

-- -------------------------------------------------3
delimiter //

create trigger after_order_item_insert
after insert on order_items
for each row
begin
	declare v_old_stock int;
    declare v_new_stock int;
    
    select stock into v_old_stock
    from products
    where prod_id = new.prod_id;
    
    set v_new_stock = v_old_stock - new.quantity;
    update products
    set stock = v_new_stock
	where prod_id = new.prod_id;
    
    insert into inventory_audit (prod_id, old_stock, new_stock, action, changed_at)
    values (new.prod_id, v_old_stock, v_new_stock, 'sale', now());
end //

delimiter ;
    
-- ----------------------------------------4
delimiter //

create trigger before_payment_update
before update on payments
for each row
begin
    
	if old.payment_status not in ('success', 'pending') then 
    signal sqlstate '45000'
	set message_text = 'Cannot refund: Payment is not in a valid state';
	end if;
    
    if new.payment_status ="refunded" and new.amount > old.amount then
    signal sqlstate '45000'
    set message_text = 'Refund amount exceeds original payment';
    end if;
    
    if old.payment_status = 'refunded' and new.payment_status = 'refunded' then 
    signal sqlstate '45000'
        set message_text = 'Payment is already refunded';
    end if;
end //

delimiter ;

 -- --------------------------------------------------5
create table product_audit (
	audit_id int auto_increment primary key,
    prod_id int not null,
    old_price decimal(10,2),
    new_price decimal(10,2),
    old_stock int,
    new_stock int,
    old_cost_price decimal(10,2),
    new_cost_price decimal(10,2),
    changed_at datetime default current_timestamp,
    foreign key (prod_id) references products(prod_id)
);

delimiter //
create trigger after_product_update
after update on products
for each row
begin
	if (old.price != new.price) or
		(old.stock != new.stock) or
		(old.cost_price != new.cost_price) then
        
        insert into product_audit (
			prod_id,
            old_price,
            new_price,
            old_stock,
            new_stock,
            old_cost_price,
            new_cost_price
        ) values (
			new.prod_id,
            old.price,
            new.price,
            old.stock,
            new.stock,
            old.cost_price,
            new.cost_price
        );
        end if;
end //

delimiter ;