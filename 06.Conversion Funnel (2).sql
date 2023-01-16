
-- first I will show you all of the pageviews we care about
-- then, I will remove the comments from my flag columns one by one to show you what that looks like

SELECT
	website_sessions.website_session_id,
    website_pageviews.pageview_url,
    website_pageviews.created_at AS pageview_created_at,   
    CASE WHEN pageview_url = '/products' THEN 1 ELSE 0 END AS prodcuts_page,
    CASE WHEN pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS mrfuzzy_page,
    CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page,
	CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END AS ship_page,
	CASE WHEN pageview_url = '/billing' THEN 1 ELSE 0 END AS bill_page,
    CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thanks_page
FROM website_sessions
LEFT JOIN website_pageviews
	ON website_sessions.website_session_id = website_pageviews.website_session_id
WHERE website_sessions.utm_source = 'gsearch'
	AND website_sessions.utm_campaign = 'nonbrand'
    AND website_pageviews.created_at BETWEEN '2012-08-05' AND '2012-09-05'    
ORDER BY
	website_sessions.website_session_id,
    website_pageviews.created_at;

-- next, we will put the previous query inside a subquery (similar to temp tables)
-- we will group by website_session_id and take the MAX() of each of the flags
-- this MAX() becomes a made_it flag for that session, to show the session made it there

SELECT
	website_session_id,
    MAX(prodcuts_page) AS product_made_it,
    MAX(mrfuzzy_page) AS mrfuzzy_made_it,
	MAX(cart_page) AS cart_made_it,
    MAX(ship_page) AS ship_made_it,
    MAX(bill_page) AS bill_made_it,
    MAX(thanks_page) AS thanks_made_it
FROM
(
SELECT
	website_sessions.website_session_id,
    website_pageviews.pageview_url,
    website_pageviews.created_at AS pageview_created_at,   
    CASE WHEN pageview_url = '/products' THEN 1 ELSE 0 END AS prodcuts_page,
    CASE WHEN pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS mrfuzzy_page,
    CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page,
	CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END AS ship_page,
	CASE WHEN pageview_url = '/billing' THEN 1 ELSE 0 END AS bill_page,
    CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thanks_page
FROM website_sessions
LEFT JOIN website_pageviews
	ON website_sessions.website_session_id = website_pageviews.website_session_id
WHERE website_sessions.utm_source = 'gsearch'
	AND website_sessions.utm_campaign = 'nonbrand'
    AND website_pageviews.created_at BETWEEN '2012-08-05' AND '2012-09-05'    
ORDER BY
	website_sessions.website_session_id,
    website_pageviews.created_at
)
AS pageview_level
GROUP BY website_session_id;

-- next, we will turn it into a temp table

CREATE TEMPORARY TABLE session_level_made_it_flags
SELECT
	website_session_id,
    MAX(prodcuts_page) AS product_made_it,
    MAX(mrfuzzy_page) AS mrfuzzy_made_it,
	MAX(cart_page) AS cart_made_it,
    MAX(ship_page) AS ship_made_it,
    MAX(bill_page) AS bill_made_it,
    MAX(thanks_page) AS thanks_made_it
FROM
(
SELECT
	website_sessions.website_session_id,
    website_pageviews.pageview_url,
    website_pageviews.created_at AS pageview_created_at,   
    CASE WHEN pageview_url = '/products' THEN 1 ELSE 0 END AS prodcuts_page,
    CASE WHEN pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS mrfuzzy_page,
    CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page,
	CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END AS ship_page,
	CASE WHEN pageview_url = '/billing' THEN 1 ELSE 0 END AS bill_page,
    CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thanks_page
FROM website_sessions
LEFT JOIN website_pageviews
	ON website_sessions.website_session_id = website_pageviews.website_session_id
WHERE website_sessions.utm_source = 'gsearch'
	AND website_sessions.utm_campaign = 'nonbrand'
    AND website_pageviews.created_at BETWEEN '2012-08-05' AND '2012-09-05'    
ORDER BY
	website_sessions.website_session_id,
    website_pageviews.created_at
)
AS pageview_level
GROUP BY website_session_id;

SELECT * FROM session_level_made_it_flags;

-- then this would produce the final ouput (part 1)

SELECT
	COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT CASE WHEN product_made_it = 1 THEN website_session_id ELSE NULL END) AS to_products,
	COUNT(DISTINCT CASE WHEN mrfuzzy_made_it = 1 THEN website_session_id ELSE NULL END) AS to_mrfuzzy,
	COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END) AS to_cart,
	COUNT(DISTINCT CASE WHEN ship_made_it = 1 THEN website_session_id ELSE NULL END) AS to_ship,
    COUNT(DISTINCT CASE WHEN bill_made_it = 1 THEN website_session_id ELSE NULL END) AS to_bill,
    COUNT(DISTINCT CASE WHEN thanks_made_it = 1 THEN website_session_id ELSE NULL END) AS to_thanks
FROM session_level_made_it_flags;

-- then we'll translate those counts to click rates for final output part 2 (click rates)
-- I'll start with the same query we just did, and show you how to calculate the rates

SELECT
	COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT CASE WHEN product_made_it = 1 THEN website_session_id ELSE NULL END)
		/ COUNT(DISTINCT website_session_id) AS lander_click_rate,
	COUNT(DISTINCT CASE WHEN mrfuzzy_made_it = 1 THEN website_session_id ELSE NULL END)
		/ COUNT(DISTINCT CASE WHEN product_made_it = 1 THEN website_session_id ELSE NULL END) AS products_click_rate,
	COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END)
		/ COUNT(DISTINCT CASE WHEN mrfuzzy_made_it = 1 THEN website_session_id ELSE NULL END) AS mrfuzzy_click_rate,
	COUNT(DISTINCT CASE WHEN ship_made_it = 1 THEN website_session_id ELSE NULL END)
		/ COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END) AS cart_click_rate,
	COUNT(DISTINCT CASE WHEN bill_made_it = 1 THEN website_session_id ELSE NULL END)
		/ COUNT(DISTINCT CASE WHEN ship_made_it = 1 THEN website_session_id ELSE NULL END) AS ship_click_rate,
	COUNT(DISTINCT CASE WHEN thanks_made_it = 1 THEN website_session_id ELSE NULL END)
		/ COUNT(DISTINCT CASE WHEN bill_made_it = 1 THEN website_session_id ELSE NULL END) AS bill_click_rate
FROM session_level_made_it_flags

    
    
    
    
    
    
    