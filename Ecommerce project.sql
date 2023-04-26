-- 1. Gsearch is the biggest driver of the business. 
-- Search for monthly trends and conversion rate for gsearch sessions and orders so it is possible to showcase the growth?

SELECT 
YEAR(website_sessions.created_at) AS yr,
MONTH(website_sessions.created_at) AS mn,
COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
COUNT(DISTINCT orders.order_id) AS orders,
COUNT(DISTINCT orders.order_id) / COUNT(DISTINCT website_sessions.website_session_id) AS conv_rate
FROM website_sessions
LEFT JOIN orders ON orders.website_session_id=website_sessions.website_session_id
WHERE website_sessions.created_at <'2012-11-27' 
AND website_sessions.utm_source='gsearch'
GROUP BY 1,2;


-- 2. Splitting out brand and non-brand campaigns separately

SELECT 
YEAR(website_sessions.created_at) AS yr,
MONTH(website_sessions.created_at) AS mn,
COUNT(DISTINCT CASE WHEN utm_campaign='nonbrand' THEN website_sessions.website_session_id ELSE NULL END) AS nonbrand_sessions,
COUNT(DISTINCT CASE WHEN utm_campaign='nonbrand' THEN orders.order_id ELSE NULL END) AS nonbrand_orders,
COUNT(DISTINCT CASE WHEN utm_campaign='brand' THEN website_sessions.website_session_id ELSE NULL END) AS brand_sessions,
COUNT(DISTINCT CASE WHEN utm_campaign='brand' THEN orders.order_id ELSE NULL END) AS brand_orders
FROM website_sessions
LEFT JOIN orders ON orders.website_session_id=website_sessions.website_session_id
WHERE website_sessions.created_at <'2012-11-27' 
AND website_sessions.utm_source='gsearch'
GROUP BY 1,2;


-- 3.Print out monthly trends split by device type(mobile vs desktop) based on GSearch sessions

SELECT 
YEAR(website_sessions.created_at) AS yr,
MONTH(website_sessions.created_at) AS mn,
COUNT(DISTINCT CASE WHEN device_type='mobile' THEN website_sessions.website_session_id ELSE NULL END) AS mobile_sessions,
COUNT(DISTINCT CASE WHEN device_type='mobile' THEN orders.order_id ELSE NULL END) AS mobile_orders,
COUNT(DISTINCT CASE WHEN device_type='desktop' THEN website_sessions.website_session_id ELSE NULL END) AS desktop_sessions,
COUNT(DISTINCT CASE WHEN device_type='desktop' THEN orders.order_id ELSE NULL END) AS desktop_orders
FROM website_sessions
LEFT JOIN orders ON orders.website_session_id=website_sessions.website_session_id
WHERE website_sessions.created_at <'2012-11-27' 
AND website_sessions.utm_source='gsearch' 
AND utm_campaign='nonbrand'
GROUP BY 1,2;

-- 4. Print out monthly trends for Gsearch, alongside monthly trends for each other channels

-- First finding the various utm sources to understand from where the website is getting traffic
SELECT DISTINCT
utm_source,
utm_campaign,
http_referer
FROM website_sessions
WHERE website_sessions.created_at <'2012-11-27';

SELECT
YEAR(website_sessions.created_at) AS yr,
MONTH(website_sessions.created_at) AS mn,
COUNT(DISTINCT CASE WHEN utm_source='gsearch' THEN website_sessions.website_session_id ELSE NULL END) AS gsearch_paid_sessions,
COUNT(DISTINCT CASE WHEN utm_source='bsearch' THEN website_sessions.website_session_id ELSE NULL END) AS bsearch_paid_sessions,
COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN website_sessions.website_session_id ELSE NULL END) AS organic_sessions,
COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN website_sessions.website_session_id ELSE NULL END) AS direct_type_sessions
FROM website_sessions
LEFT JOIN orders ON orders.website_session_id=website_sessions.website_session_id
WHERE website_sessions.created_at <'2012-11-27' 
GROUP BY 1,2;

-- 5. For gsearch lander test estimate the revenue and compare to compared to home landing page

-- Step needed to find the first time page was seen
SELECT MIN(website_pageview_id) AS first_pgv
FROM website_pageviews
WHERE pageview_url='/lander-1';

CREATE TEMPORARY TABLE first_test_pageviews
SELECT
website_pageviews.website_session_id,
MIN(website_pageview_id) AS first_pgv
FROM website_pageviews
INNER JOIN website_sessions ON website_sessions.website_session_id=website_pageviews.website_session_id
WHERE website_pageviews.website_pageview_id >= 23504
AND website_sessions.created_at < '2012-07-28'
AND utm_source='gsearch'
AND utm_campaign='nonbrand'
GROUP BY website_pageviews.website_session_id;


-- Step needed for bringing in landing page to each sessions
CREATE TEMPORARY TABLE nonbrand_wlandingpages
SELECT first_test_pageviews.website_session_id, website_pageviews.pageview_url AS landing_page
FROM first_test_pageviews
LEFT JOIN website_pageviews ON website_pageviews.website_pageview_id=first_test_pageviews.first_pgv
WHERE website_pageviews.pageview_url IN('/home','/lander-1');

-- Create another temporary table to have orders data
CREATE TEMPORARY TABLE nonbrand_w_orders
SELECT
nonbrand_wlandingpages.website_session_id,
nonbrand_wlandingpages.landing_page,
orders.order_id AS order_id
FROM nonbrand_wlandingpages
LEFT JOIN orders ON orders.website_session_id=nonbrand_wlandingpages.website_session_id;

-- Calculating the conv_rate for both home and lander-1 landing pages
SELECT
landing_page,
COUNT(DISTINCT website_session_id) AS sessions,
COUNT(DISTINCT order_id) AS orders,
COUNT(DISTINCT order_id) / COUNT(DISTINCT website_session_id) AS conv_rate
FROM nonbrand_w_orders
GROUP BY landing_page;

-- 0.0318 for home and 0.0406 for lander = 0.0088 difference

-- Finding the most recent pageview for gsearch nonbrand where the traffic was sent to /home landing page

SELECT 
MAX(website_sessions.website_session_id) AS mostrecent_gsearch_nonbrand_home_pg
FROM website_pageviews
LEFT JOIN website_sessions ON website_sessions.website_session_id=website_pageviews.website_session_id
WHERE pageview_url='/home'
AND website_sessions.created_at < '2012-11-27' -- date of assignment required
AND utm_source='gsearch'
AND utm_campaign='nonbrand';

-- 17145 is the most recent website_session_id

SELECT COUNT(website_session_id) AS sessions_since_test
FROM website_sessions
WHERE website_session_id>17145
AND website_sessions.created_at < '2012-11-27'
AND utm_source='gsearch'
AND utm_campaign='nonbrand';

-- 22972 website sessions since the test
-- 22972 * 0.0088 incremental conversion = approximately 202 incremental orders

-- 6. show a full conversion funnel from each of the two pages to orders
-- CREATE TEMPORARY TABLE funnel_status
SELECT
website_session_id,
MAX(home_page) as saw_homepage,
MAX(lander1_page) as saw_lander1,
MAX(product_page) as saw_productpage,
MAX(mr_fuzzy_page) as saw_mrfuzzypage,
MAX(cart_page) as saw_cartpage,
MAX(shipping_page) as saw_shippingpage,
MAX(billing_page) as saw_billingpage,
MAX(order_page) as saw_orderpage
FROM
(SELECT website_sessions.website_session_id, website_pageviews.pageview_url,
CASE WHEN pageview_url='/home' THEN 1 ELSE 0 END AS home_page,
CASE WHEN pageview_url='/lander-1' THEN 1 ELSE 0 END AS lander1_page,
CASE WHEN pageview_url='/products' THEN 1 ELSE 0 END AS product_page,
CASE WHEN pageview_url='/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS mr_fuzzy_page,
CASE WHEN pageview_url='/cart' THEN 1 ELSE 0 END AS cart_page,
CASE WHEN pageview_url='/shipping' THEN 1 ELSE 0 END AS shipping_page,
CASE WHEN pageview_url='/billing' THEN 1 ELSE 0 END AS billing_page,
CASE WHEN pageview_url='/thank-you-for-your-order' THEN 1 ELSE 0 END AS order_page
FROM website_sessions
LEFT JOIN website_pageviews ON website_sessions.website_session_id=website_pageviews.website_session_id
WHERE website_pageviews.created_at BETWEEN '2012-06-19'AND '2012-07-28'
AND website_sessions.utm_source='gsearch'
AND website_sessions.utm_campaign='nonbrand'
ORDER BY 1,2) AS pageview_funnel
GROUP BY 1;

-- final output.1 of the funnel for homepage and lander1
SELECT 
CASE WHEN saw_homepage=1 THEN 'saw_homepage'
WHEN saw_lander1=1 THEN 'saw_lander1'
ELSE 'wrong data'
END AS segment,
COUNT(DISTINCT website_session_id) AS n_sessions,
COUNT(DISTINCT CASE WHEN saw_productpage=1 THEN website_session_id ELSE NULL END) AS to_products,
COUNT(DISTINCT CASE WHEN saw_mrfuzzypage=1 THEN website_session_id ELSE NULL END) AS to_mrfuzzy,
COUNT(DISTINCT CASE WHEN saw_cartpage=1 THEN website_session_id ELSE NULL END) AS to_cart,
COUNT(DISTINCT CASE WHEN saw_shippingpage=1 THEN website_session_id ELSE NULL END) AS to_shipping,
COUNT(DISTINCT CASE WHEN saw_billingpage=1 THEN website_session_id ELSE NULL END) AS to_billing,
COUNT(DISTINCT CASE WHEN saw_orderpage=1 THEN website_session_id ELSE NULL END) AS to_order
FROM funnel_status
GROUP BY 1;


-- final output.2 of the clickthroughrate funnel for homepage and lander1
SELECT 
CASE WHEN saw_homepage=1 THEN 'saw_homepage'
WHEN saw_lander1=1 THEN 'saw_lander1'
ELSE 'wrong data'
END AS segment,
COUNT(DISTINCT website_session_id) AS n_sessions,
COUNT(DISTINCT CASE WHEN saw_productpage=1 THEN website_session_id ELSE NULL END) / COUNT(DISTINCT website_session_id) AS ctr_products,
COUNT(DISTINCT CASE WHEN saw_mrfuzzypage=1 THEN website_session_id ELSE NULL END) / COUNT(DISTINCT website_session_id) AS ctr_mrfuzzy,
COUNT(DISTINCT CASE WHEN saw_cartpage=1 THEN website_session_id ELSE NULL END) / COUNT(DISTINCT website_session_id) AS ctr_cart,
COUNT(DISTINCT CASE WHEN saw_shippingpage=1 THEN website_session_id ELSE NULL END) / COUNT(DISTINCT website_session_id) AS ctr_shipping,
COUNT(DISTINCT CASE WHEN saw_billingpage=1 THEN website_session_id ELSE NULL END) / COUNT(DISTINCT website_session_id) AS ctr_billing,
COUNT(DISTINCT CASE WHEN saw_orderpage=1 THEN website_session_id ELSE NULL END) / COUNT(DISTINCT website_session_id) AS ctr_order
FROM funnel_status
GROUP BY 1;