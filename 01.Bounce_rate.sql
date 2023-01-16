
-- STEP 1 find the first website_pageview_id for relevant sessions
-- STEP 2 identify the landing page of each session
-- STEP 3 counting pageviews for each session, to identify "bounces"
-- STEP 4 summarizing total sessions and bounced sessions, by LP

-- 1/5 finding the MIN website_pageview_id associated with each session we care about
-- same query as above, but this time we're storing the dataset as a temporary table

CREATE TEMPORARY TABLE first_pageviews_demo
SELECT
	website_pageviews.website_session_id,
    MIN(website_pageviews.website_pageview_id) AS min_pageview_id
FROM website_pageviews
	INNER JOIN website_sessions
		ON website_sessions.website_session_id = website_pageviews.website_session_id
        AND website_sessions.created_at BETWEEN '2014-01-01' AND '2014-02-01'
GROUP BY 1
;
SELECT * FROM first_pageviews_demo;

-- 2/5 next, we'll bring in the landing page to each session

CREATE TEMPORARY TABLE sessions_w_landing_page_demo
SELECT
	first_pageviews_demo.website_session_id,
    website_pageviews.pageview_url AS landing_page
FROM first_pageviews_demo
	LEFT JOIN website_pageviews
		ON website_pageviews.website_pageview_id = first_pageviews_demo.min_pageview_id
        ;
SELECT * FROM sessions_w_landing_page_demo;

-- 3/5 next, we make a table to include a count of pageviews per session
-- first, I'll show you all of the sessions. Then we'll limit to bounced sessions and create a temp table

CREATE TEMPORARY TABLE bounced_sessions_only -- to create after checking a result before creating
SELECT
	sessions_w_landing_page_demo.website_session_id,
    sessions_w_landing_page_demo.landing_page,
    COUNT(website_pageviews.website_pageview_id) AS count_of_pages_viewed
FROM sessions_w_landing_page_demo
	LEFT JOIN website_pageviews
		ON website_pageviews.website_session_id = sessions_w_landing_page_demo.website_session_id
GROUP BY 1,2
HAVING
	COUNT(website_pageviews.website_pageview_id) = 1
;
SELECT * FROM bounced_sessions_only;

-- 4/5 we will do this first, then we will summarize with a count after

SELECT
	sessions_w_landing_page_demo.landing_page,
    sessions_w_landing_page_demo.website_session_id,
    bounced_sessions_only.website_session_id AS bounced_website_session_id
FROM sessions_w_landing_page_demo
	LEFT JOIN bounced_sessions_only
		ON sessions_w_landing_page_demo.website_session_id = bounced_sessions_only.website_session_id
ORDER BY 2
;

-- 5/5 final output
	-- we'll use the same query we previously ran and run a count of records
    -- we'll group by landing page and then we'll add a bounce rate column

SELECT
	sessions_w_landing_page_demo.landing_page,
    COUNT(DISTINCT sessions_w_landing_page_demo.website_session_id) AS sessions,
    COUNT(DISTINCT bounced_sessions_only.website_session_id) AS bounced_sessions,
    COUNT(DISTINCT bounced_sessions_only.website_session_id)/
		COUNT(DISTINCT sessions_w_landing_page_demo.website_session_id) AS bounce_rate
FROM sessions_w_landing_page_demo
	LEFT JOIN bounced_sessions_only
		ON sessions_w_landing_page_demo.website_session_id = bounced_sessions_only.website_session_id
GROUP BY 1
;


    
    
    
    
    
    
    
    
    
    
























