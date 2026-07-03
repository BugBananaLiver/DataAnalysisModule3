USE coffeeshop_db;

-- =========================================================
-- JOINS & RELATIONSHIPS PRACTICE
-- =========================================================

-- Q1) Join products to categories: list product_name, category_name, price.
SELECT
	products.name,
    categories.name,
    products.price
FROM products 
LEFT JOIN categories ON products.category_id = categories.category_id;

-- Q2) For each order item, show: order_id, order_datetime, store_name,
--     product_name, quantity, line_total (= quantity * products.price).
--     Sort by order_datetime, then order_id.
SELECT
	orders.order_id,
    orders.order_datetime,
    stores.name AS store_name,
    products.name,
    order_items.quantity,
    (order_items.quantity * products.price) AS line_total
FROM orders 
LEFT JOIN order_items ON orders.order_id = order_items.order_id
LEFT JOIN products ON order_items.product_id = products.product_id
LEFT JOIN stores ON orders.store_id = stores.store_id
ORDER BY orders.order_datetime AND orders.order_id;
    
-- Q3) Customer order history (PAID only):
--     For each order, show customer_name, store_name, order_datetime,
--     order_total (= SUM(quantity * products.price) per order).
SELECT
	CONCAT(customers.first_name, ' ', customers.last_name) AS customer_name,
    stores.name AS store_name,
    orders.order_datetime,
    SUM(order_items.quantity * products.price) AS order_total
FROM customers
LEFT JOIN orders ON customers.customer_id = orders.customer_id
LEFT JOIN stores ON orders.store_id = stores.store_id
LEFT JOIN order_items ON order_items.order_id = orders.order_id
LEFT JOIN products ON order_items.product_id = products.product_id
WHERE orders.status = 'PAID'
GROUP BY orders.order_id, customers.first_name, customers.last_name, stores.name, orders.order_datetime;
    

-- Q4) Left join to find customers who have never placed an order.
--     Return first_name, last_name, city, state.
SELECT
	customers.first_name,
    customers.last_name,
    customers.city,
    customers.state
FROM customers
LEFT JOIN orders ON customers.customer_id = orders.customer_id
WHERE orders.order_id = TRUE;
-- Q5) For each store, list the top-selling product by units (PAID only).
--     Return store_name, product_name, total_units.
--     Hint: Use a window function (ROW_NUMBER PARTITION BY store) or a correlated subquery.
SELECT *
FROM (
SELECT
	stores.name AS store_name,
    products.name AS product_name,
    SUM(order_items.quantity) as total_units
FROM stores
LEFT JOIN orders ON stores.store_id = orders.store_id
LEFT JOIN order_items ON orders.order_id = order_items.order_id
LEFT JOIN products ON order_items.product_id = products.product_id
WHERE 
orders.status = 'PAID'
GROUP BY 
	stores.name,
    products.name) t
WHERE total_units = (
	SELECT MAX(t2.total_units)
    FROM(
SELECT
	stores.name AS store_name,
    products.name AS product_name,
    SUM(order_items.quantity) as total_units
FROM stores
LEFT JOIN orders ON stores.store_id = orders.store_id
LEFT JOIN order_items ON orders.order_id = order_items.order_id
LEFT JOIN products ON order_items.product_id = products.product_id
WHERE 
orders.status = 'PAID'
GROUP BY 
	stores.name,
    products.name) t2
WHERE t2.store_name = t.store_name);
-- Q6) Inventory check: show rows where on_hand < 12 in any store.
--     Return store_name, product_name, on_hand.
SELECT
	stores.name AS store_name,
    products.name AS product_name,
    inventory.on_hand
FROM inventory
LEFT JOIN products ON inventory.product_id = products.product_id
LEFT JOIN stores ON inventory.store_id = stores.store_id
WHERE inventory.on_hand <12;
-- Q7) Manager roster: list each store's manager_name and hire_date.
--     (Assume title = 'Manager').
SELECT
	stores.name AS store_name,
	CONCAT(employees.first_name, ' ', employees.last_name) AS manager_name,
    employees.hire_date
FROM employees
LEFT JOIN stores ON employees.store_id = stores.store_id
WHERE employees.title = 'Manager';
-- Q8) Using a subquery/CTE: list products whose total PAID revenue is above
--     the average PAID product revenue. Return product_name, total_revenue.
SELECT 
	product_name,
	total_revenue
FROM
(SELECT
	products.name AS product_name,
	SUM(order_items.quantity * products.price) AS total_revenue
FROM order_items
LEFT JOIN products ON order_items.product_id = products.product_id
LEFT JOIN orders ON order_items.order_id = orders.order_id
WHERE orders.status = 'PAID'
GROUP BY product_name) AS revenue_table
WHERE total_revenue >
(
	SELECT AVG(total_revenue)
	FROM
(SELECT
	products.name AS product_name,
	SUM(order_items.quantity * products.price) AS total_revenue
FROM order_items
LEFT JOIN products ON order_items.product_id = products.product_id
LEFT JOIN orders ON order_items.order_id = orders.order_id
WHERE orders.status = 'PAID'
GROUP BY product_name) AS avg_table);
-- Q9) Churn-ish check: list customers with their last PAID order date.
--     If they have no PAID orders, show NULL.
--     Hint: Put the status filter in the LEFT JOIN's ON clause to preserve non-buyer rows.
SELECT 
	CONCAT(customers.first_name, ' ', customers.last_name),
    max(DATE(orders.order_datetime)) AS last_paid_order
FROM customers
LEFT JOIN orders ON customers.customer_id = orders.customer_id AND orders.status = 'PAID'
GROUP BY
	customers.customer_id,
    customers.first_name,
    customers.last_name;
    
-- Q10) Product mix report (PAID only):
--     For each store and category, show total units and total revenue (= SUM(quantity * products.price)).
SELECT
	
