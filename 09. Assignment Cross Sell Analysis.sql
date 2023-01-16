-- Assignment Cross Sell Analysis
 -- 2013-09-25 = add 2nd on /cart: 1 mon before/after – CTR, AVG products per order, AOV, Revenue per /cart page view

-- Step 1: Identify the relevant /cart page views and their sessions
-- Step 2: See which of those /cart sessions clicked through to the shipping page
-- Step 3: Find the orders associated with the /cart sessions. Analyze products purchased, AOV
-- Step 4: Aggregate and analyze a summary of our findings


-- Step 1: Identify the relevant /cart page views and their sessions
-- because the request is based on customers who saw the cart page

CREATE TEMPORARY TABLE sessions_seeing_cart
SELECT
	CASE
		WHEN created_at < '2013-09-25' THEN 'A. Pre_Cross_Sell'
        WHEN created_at >= '2013-01-06' THEN 'B. Post_Cross_Sell'
        ELSE 'oh...'
	END AS time_period,
    website_session_id AS cart_session_id,
    website_pageview_id AS cart_pageview_id
FROM website_pageviews
WHERE created_at BETWEEN '2013-08-25' AND '2013-10-25'
	AND pageview_url = '/cart';
SELECT * FROM sessions_seeing_cart;

-- Step 2: See which of those /cart sessions clicked through to the shipping page
-- Finding pageview_id after /cart

CREATE TEMPORARY TABLE cart_sessions_seeing_another_page
SELECT
	sessions_seeing_cart.time_period,
    sessions_seeing_cart.cart_session_id,
    MIN(website_pageviews.website_pageview_id) AS pv_id_after_cart
FROM sessions_seeing_cart
LEFT JOIN website_pageviews
	ON website_pageviews.website_session_id = sessions_seeing_cart.cart_session_id
	AND website_pageviews.website_pageview_id > sessions_seeing_cart.cart_pageview_id
GROUP BY
	sessions_seeing_cart.time_period,
    sessions_seeing_cart.cart_session_id
HAVING
	MIN(website_pageviews.website_pageview_id) IS NOT NULL; -- without abandoned after /cart
SELECT * FROM cart_sessions_seeing_another_page;

-- Step 3: Find the orders associated with the /cart sessions.

CREATE TEMPORARY TABLE pre_post_sessions_orders
SELECT
	time_period,
    cart_session_id,
    order_id,
    items_purchased,
    price_usd
FROM sessions_seeing_cart
INNER JOIN orders -- sessions only with orders
	ON sessions_seeing_cart.cart_session_id = orders.website_session_id;
SELECT * FROM pre_post_sessions_orders;
   
-- first, we'll look at this select statement: 2 JOINs
-- then we'll turn it into a subquery for final result

SELECT
	sessions_seeing_cart.time_period,
    sessions_seeing_cart.cart_session_id,
    CASE WHEN cart_sessions_seeing_another_page.cart_session_id IS NULL THEN 0 ELSE 1 END AS clicked_to_another_page,
    CASE WHEN pre_post_sessions_orders.order_id IS NULL THEN 0 ELSE 1 END AS placed_order,
    pre_post_sessions_orders.items_purchased,
    pre_post_sessions_orders.price_usd
FROM sessions_seeing_cart
LEFT JOIN cart_sessions_seeing_another_page
	ON sessions_seeing_cart.cart_session_id = cart_sessions_seeing_another_page.cart_session_id
LEFT JOIN pre_post_sessions_orders
	ON sessions_seeing_cart.cart_session_id = pre_post_sessions_orders.cart_session_id
ORDER BY cart_session_id;

SELECT
	time_period,
    COUNT(DISTINCT cart_session_id) AS cart_sessions,
    SUM(clicked_to_another_page) AS clickthroughs,
    SUM(clicked_to_another_page)/COUNT(DISTINCT cart_session_id) AS cart_ctr,
    -- SUM(placed_order) AS orders_placed,
    -- SUM(items_purchased) AS products_purchased,
    SUM(items_purchased)/SUM(placed_order) AS products_per_order,
    -- SUM(price_usd) AS revenue,
    SUM(price_usd)/SUM(placed_order) AS aov,
    SUM(price_usd)/COUNT(DISTINCT cart_session_id) AS rev_per_cart_session    
FROM (
SELECT
	sessions_seeing_cart.time_period,
    sessions_seeing_cart.cart_session_id,
    CASE WHEN cart_sessions_seeing_another_page.cart_session_id IS NULL THEN 0 ELSE 1 END AS clicked_to_another_page,
    CASE WHEN pre_post_sessions_orders.order_id IS NULL THEN 0 ELSE 1 END AS placed_order,
    pre_post_sessions_orders.items_purchased,
    pre_post_sessions_orders.price_usd
FROM sessions_seeing_cart
LEFT JOIN cart_sessions_seeing_another_page
	ON sessions_seeing_cart.cart_session_id = cart_sessions_seeing_another_page.cart_session_id
LEFT JOIN pre_post_sessions_orders
	ON sessions_seeing_cart.cart_session_id = pre_post_sessions_orders.cart_session_id
ORDER BY cart_session_id
)
AS full_data
GROUP BY time_period;


-- ANOTHER ASSIGNMENT #2 -----------------------------------------------------------

SELECT
	CASE
		WHEN website_sessions.created_at < '2013-12-12' THEN 'A. Pre_Birthday_Bear'
        WHEN website_sessions.created_at >= '2013-12-12' THEN 'B. Post_Birthday_Bear'
        ELSE 'oh...'
	END AS time_period,
    -- COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    -- COUNT(DISTINCT orders.order_id) AS orders,
    COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT website_sessions.website_session_id) AS conv_rate,
    -- SUM(orders.price_usd) AS total_revenue,
    -- SUM(orders.items_purchased) AS total_products_sold,
    SUM(orders.price_usd)/COUNT(DISTINCT orders.order_id) AS aov,
    SUM(orders.items_purchased)/COUNT(DISTINCT orders.order_id) AS products_per_order,
    SUM(orders.price_usd)/COUNT(DISTINCT website_sessions.website_session_id) AS revenue_per_session
FROM website_sessions
LEFT JOIN orders
	ON orders.website_session_id = website_sessions.website_session_id
WHERE website_sessions.created_at BETWEEN '2013-11-12' AND '2014-01-12'
GROUP BY time_period










