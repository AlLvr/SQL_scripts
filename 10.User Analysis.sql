 -- -------------------1

-- STEP 1: Identify the relevant new sessions
-- STEP 2: Using the user_id values from step 1 to find any repeat sessions those users had
-- STEP 3: Analyze the data at the user level (how many sessions did each user have?)
-- STEP 4: Aggregate the user-level analysis to generate your behavioral analysis


-- Identify the relevant new sessions (subquery)

SELECT
	user_id,
    website_session_id
FROM website_sessions
WHERE created_at < '2014-11-01'
	AND created_at >= '2014-01-01'
    AND is_repeat_session = 0;


-- To find any repeat sessions those users had

CREATE TEMPORARY TABLE sessions_w_repeats
SELECT
	new_sessions.user_id,
    new_sessions.website_session_id AS new_session_id,
    website_sessions.website_session_id AS repeat_session_id
FROM
(
SELECT
	user_id,
    website_session_id
FROM website_sessions
WHERE created_at < '2014-11-01'
	AND created_at >= '2014-01-01'
    AND is_repeat_session = 0
)
AS new_sessions
LEFT JOIN website_sessions
	ON website_sessions.user_id = new_sessions.user_id
    AND website_sessions.is_repeat_session = 1
    AND website_sessions.website_session_id > new_sessions.website_session_id -- session was later then new session
    AND website_sessions.created_at < '2014-11-01'
	AND website_sessions.created_at >= '2014-01-01';
SELECT * FROM sessions_w_repeats;


-- Analyze the data at the user level (how many sessions did each user have?) – (subquery)

SELECT
	user_id,
    COUNT(DISTINCT new_session_id) AS new_sessions,
    COUNT(DISTINCT repeat_session_id) AS repeat_sessions
FROM sessions_w_repeats
GROUP BY user_id
ORDER BY repeat_sessions DESC;


-- Aggregate the user-level analysis to generate your behavioral analysis

SELECT
	repeat_sessions,
    COUNT(DISTINCT user_id) AS users
FROM
(
SELECT
	user_id,
    COUNT(DISTINCT new_session_id) AS new_sessions,
    COUNT(DISTINCT repeat_session_id) AS repeat_sessions
FROM sessions_w_repeats
GROUP BY user_id
ORDER BY repeat_sessions DESC
)
AS user_level
GROUP BY repeat_sessions;


-- -------------------2

-- STEP 1: Identify the relevant new sessions
-- STEP 2: Using the user_id values from step 1 to find any repeat sessions those users had
-- STEP 3: Find the created_at times for first and second sessions
-- STEP 4: Find the differences between first and second sessions at a user level
-- STEP 5: Aggregate the user-level analysis to find the average, min, max


-- steps 1-2: identifying the relevant new sessions & finding any repeat sessions those users had

CREATE TEMPORARY TABLE sessions_w_repeats_for_time_diff
SELECT
	new_sessions.user_id,
    new_sessions.website_session_id AS new_session_id,
    new_sessions.created_at AS new_session_created_at,
    website_sessions.website_session_id AS repeat_session_id,
    website_sessions.created_at AS repeat_session_created_at
FROM
(
SELECT
	user_id,
    website_session_id,
    created_at
FROM website_sessions
WHERE created_at < '2014-11-03'
	AND created_at >= '2014-01-01'
    AND is_repeat_session = 0
)
AS new_sessions
LEFT JOIN website_sessions
	ON website_sessions.user_id = new_sessions.user_id
    AND website_sessions.is_repeat_session = 1
    AND website_sessions.website_session_id > new_sessions.website_session_id -- session was later then new session
    AND website_sessions.created_at < '2014-11-03'
	AND website_sessions.created_at >= '2014-01-01';
SELECT * FROM sessions_w_repeats_for_time_diff;

-- step 3: finding the created_at times for first and second sessions

SELECT
	user_id,
    new_session_id,
    new_session_created_at,
    MIN(repeat_session_id) AS second_session_id,
    MIN(repeat_session_created_at) AS second_session_created_at
FROM sessions_w_repeats_for_time_diff
WHERE repeat_session_id IS NOT NULL
GROUP BY
	user_id,
    new_session_id,
    new_session_created_at;

-- step 4: finding the differences between first and second sessions at a user level

CREATE TEMPORARY TABLE users_first_to_second
SELECT
	user_id,
    DATEDIFF(second_session_created_at, new_session_created_at) AS days_first_to_second_session
FROM
(
SELECT
	user_id,
    new_session_id,
    new_session_created_at,
    MIN(repeat_session_id) AS second_session_id, -- the first repeat session
    MIN(repeat_session_created_at) AS second_session_created_at
FROM sessions_w_repeats_for_time_diff
WHERE repeat_session_id IS NOT NULL
GROUP BY
	user_id,
    new_session_id,
    new_session_created_at
)
AS first_second;
SELECT * FROM users_first_to_second;

-- step 5: aggregating the user-level analysis to find the average, min, max

SELECT
	AVG(days_first_to_second_session) AS avg_days_first_to_second,
    MIN(days_first_to_second_session) AS min_days_first_to_second,
    MAX(days_first_to_second_session) AS max_days_first_to_second
FROM users_first_to_second;


-- -------------------3


SELECT
	CASE
		WHEN utm_source IS NULL AND http_referer IN('https://www.gsearch.com','https://www.bsearch.com') THEN 'organic_search'
        WHEN utm_campaign = 'nonbrand' THEN 'paid_nonbrand'
        WHEN utm_campaign = 'brand' THEN 'paid_brand'
        WHEN utm_source IS NULL AND http_referer IS NULL THEN 'direct_type_in'
        WHEN utm_source = 'socialbook' THEN 'paid_social'
	END AS channel_group,
    COUNT(CASE WHEN is_repeat_session = 0 THEN website_session_id ELSE NULL END) AS new_sessions,
    COUNT(CASE WHEN is_repeat_session = 1 THEN website_session_id ELSE NULL END) AS repeat_sessions
FROM website_sessions
WHERE created_at < '2014-11-05'
	AND created_at >= '2014-01-01'
GROUP BY channel_group
ORDER BY repeat_sessions DESC;



-- -------------------4


SELECT
	is_repeat_session,
    COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT website_sessions.website_session_id) AS conv_rate,
	SUM(price_usd)/COUNT(DISTINCT website_sessions.website_session_id) AS rev_per_session
FROM website_sessions
LEFT JOIN orders
	ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at < '2014-11-08'
	AND website_sessions.created_at >= '2014-01-01'
GROUP BY is_repeat_session;











