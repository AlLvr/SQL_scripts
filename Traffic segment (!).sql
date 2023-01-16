SELECT
    *,
    CASE
		WHEN http_referer IS NULL THEN 'direct_type_in'
		WHEN http_referer = 'https://www.gsearch.com' THEN 'gsearch_organic'
        WHEN http_referer = 'https://www.bsearch.com' THEN 'bsearch_organic'
        ELSE 'other'
	END
FROM website_sessions
WHERE website_session_id BETWEEN 100000 AND 115000 -- arbitrary range
	AND utm_source IS NULL
;

SELECT
    CASE
		WHEN http_referer IS NULL THEN 'direct_type_in'
		WHEN http_referer = 'https://www.gsearch.com' THEN 'gsearch_organic'
        WHEN http_referer = 'https://www.bsearch.com' THEN 'bsearch_organic'
        ELSE 'other'
	END AS traffic,
	COUNT(DISTINCT website_session_id) AS sessions
FROM website_sessions
WHERE website_session_id BETWEEN 100000 AND 115000 -- arbitrary range
	AND utm_source IS NULL
GROUP BY traffic
ORDER BY sessions DESC
;

SELECT
    CASE
		WHEN http_referer IS NULL THEN 'direct_type_in'
		WHEN http_referer = 'https://www.gsearch.com' AND utm_source IS NULL THEN 'gsearch_organic'
        WHEN http_referer = 'https://www.bsearch.com' AND utm_source IS NULL THEN 'bsearch_organic'
        ELSE 'other'
	END AS traffic,
	COUNT(DISTINCT website_session_id) AS sessions
FROM website_sessions
WHERE website_session_id BETWEEN 100000 AND 115000 -- arbitrary range
	-- AND utm_source IS NULL
GROUP BY traffic
ORDER BY sessions DESC
;

SELECT
	CASE
		WHEN http_referer IS NULL AND is_repeat_session = 0 THEN 'new_direcrt_type_in'
        WHEN http_referer IS NULL AND is_repeat_session = 1 THEN 'repeat_direcrt_type_in'
		WHEN http_referer IN('https://www.gsearch.com','https://www.bsearch.com') AND is_repeat_session = 0 THEN 'new_organic'
		WHEN http_referer IN('https://www.gsearch.com','https://www.bsearch.com') AND is_repeat_session = 1 THEN 'repeat_organic'
		ELSE 'other' -- or NULL
    END AS traffic,
    COUNT(DISTINCT website_session_id) AS sessions
FROM website_sessions
WHERE website_session_id BETWEEN 100000 AND 115000 -- arbitrary range
	AND utm_source IS NULL -- not paid traffic
GROUP BY traffic
;

SELECT * FROM website_sessions;


SELECT DISTINCT
	utm_source,
    utm_campaign,
    http_referer,
    is_repeat_session,
    CASE
		-- WHEN http_referer IS NULL THEN 'direct_type_in'
        WHEN http_referer IS NULL AND is_repeat_session = 0 THEN 'direcrt_type_in_new'
		WHEN http_referer IS NULL AND is_repeat_session = 1 THEN 'direcrt_type_in_repeat'
		-- WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN 'organic_search'
        WHEN utm_source IS NULL AND http_referer = 'https://www.gsearch.com' AND is_repeat_session = 0 THEN 'organic_gsearch_new'
        WHEN utm_source IS NULL AND http_referer = 'https://www.gsearch.com' AND is_repeat_session = 1 THEN 'organic_gsearch_repeat'
        WHEN utm_source IS NULL AND http_referer = 'https://www.bsearch.com' AND is_repeat_session = 0 THEN 'organic_bsearch_new'
        WHEN utm_source IS NULL AND http_referer = 'https://www.bsearch.com' AND is_repeat_session = 1 THEN 'organic_bsearch_repeat'
        -- WHEN utm_source IS NULL AND http_referer IN('https://www.gsearch.com','https://www.bsearch.com') AND is_repeat_session = 0 THEN 'new_organic'
		-- WHEN utm_source IS NULL AND http_referer IN('https://www.gsearch.com','https://www.bsearch.com') AND is_repeat_session = 1 THEN 'repeat_organic'
        WHEN utm_source IS NOT NULL THEN 'paid_search'
        ELSE 'other'
	END AS CASE_
FROM website_sessions
ORDER BY CASE_ 
;

/* ASSIGNMENT: Could you pull organic search, direct type in, and paid brand search
sessions by month, and show those sessions as a % of paid search nonbrand? */

SELECT DISTINCT
	utm_source,
    utm_campaign,
    http_referer
FROM website_sessions
WHERE created_at < '2012-12-23'
;

SELECT DISTINCT
	CASE
		WHEN utm_source IS NULL AND http_referer IN('https://www.gsearch.com','https://www.bsearch.com') THEN 'organic_search'
        WHEN utm_campaign = 'nonbrand' THEN 'paid_nonbrand'
        WHEN utm_campaign = 'brand' THEN 'paid_brand'
        WHEN utm_source IS NULL AND http_referer IS NULL THEN 'direct_type_in'
	END AS channel_group,
    utm_source,
    utm_campaign,
    http_referer
FROM website_sessions
WHERE created_at < '2012-12-23'
;

SELECT
	website_session_id,
    created_at,
	CASE
		WHEN utm_source IS NULL AND http_referer IN('https://www.gsearch.com','https://www.bsearch.com') THEN 'organic_search'
        WHEN utm_campaign = 'nonbrand' THEN 'paid_nonbrand'
        WHEN utm_campaign = 'brand' THEN 'paid_brand'
        WHEN utm_source IS NULL AND http_referer IS NULL THEN 'direct_type_in'
	END AS channel_group
FROM website_sessions
WHERE created_at < '2012-12-23'
;

SELECT
	YEAR(created_at) AS yr,
	MONTH(created_at) AS mon,
    COUNT(DISTINCT CASE WHEN channel_group = 'paid_nonbrand' THEN website_session_id ELSE 0 END) AS nonbrand,
    COUNT(DISTINCT CASE WHEN channel_group = 'paid_brand' THEN website_session_id ELSE 0 END) AS brand,
    COUNT(DISTINCT CASE WHEN channel_group = 'paid_brand' THEN website_session_id ELSE 0 END)
		/COUNT(DISTINCT CASE WHEN channel_group = 'paid_nonbrand' THEN website_session_id ELSE 0 END) AS brand_pct_of_nonbrand,
        COUNT(DISTINCT CASE WHEN channel_group = 'direct_type_in' THEN website_session_id ELSE 0 END) AS direct,
    COUNT(DISTINCT CASE WHEN channel_group = 'direct_type_in' THEN website_session_id ELSE 0 END)
		/COUNT(DISTINCT CASE WHEN channel_group = 'paid_nonbrand' THEN website_session_id ELSE 0 END) AS direct_pct_of_nonbrand,
        COUNT(DISTINCT CASE WHEN channel_group = 'organic_search' THEN website_session_id ELSE 0 END) AS organic,
    COUNT(DISTINCT CASE WHEN channel_group = 'organic_search' THEN website_session_id ELSE 0 END)
		/COUNT(DISTINCT CASE WHEN channel_group = 'paid_nonbrand' THEN website_session_id ELSE 0 END) AS orhanic_pct_of_nonbrand
FROM(
SELECT
	website_session_id,
    created_at,
	CASE
		WHEN utm_source IS NULL AND http_referer IN('https://www.gsearch.com','https://www.bsearch.com') THEN 'organic_search'
        WHEN utm_campaign = 'nonbrand' THEN 'paid_nonbrand'
        WHEN utm_campaign = 'brand' THEN 'paid_brand'
        WHEN utm_source IS NULL AND http_referer IS NULL THEN 'direct_type_in'
	END AS channel_group
FROM website_sessions
WHERE created_at < '2012-12-23'
) AS sessions_w_channel_group
GROUP BY yr, mon
;





















