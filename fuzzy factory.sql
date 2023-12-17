-- AB Testing for home vs lander-1 page - Count the sessions that landed in the homepage vs lander-1page 
-- and clicked through the next pages, between 2012-06-19 and 2012-07-28 when the factory added Lander-1page.

SELECT `pageview_url` FROM `website_pageviews` GROUP BY 1;

CREATE TEMPORARY TABLE first_page_sessions
SELECT wp.pageview_url, ws.website_session_id 
FROM website_sessions ws LEFT JOIN website_pageviews wp ON ws.website_session_id = wp.website_session_id
WHERE ws.utm_source = 'gsearch'  AND ws.utm_campaign = 'nonbrand' AND wp.pageview_url IN ('/home','/lander-1') 
AND ws.created_at BETWEEN '2012-06-19' AND '2012-07-28';

CREATE TEMPORARY TABLE sessions_madeit_to_next_page
SELECT ws.website_session_id, 
CASE WHEN wp.pageview_url = '/products' THEN 1 ELSE NULL END AS to_product,  
CASE WHEN wp.pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE NULL END AS to_mr_fuzzy,
CASE WHEN wp.pageview_url = '/cart' THEN 1 ELSE NULL END AS to_cart,
CASE WHEN wp.pageview_url = '/shipping' THEN 1 ELSE NULL END AS to_shipping,
CASE WHEN wp.pageview_url = '/billing' THEN 1 ELSE NULL END AS to_billing,
CASE WHEN wp.pageview_url = '/thank-you-for-your-order' THEN 1 ELSE NULL END AS to_thank_you
FROM website_sessions ws LEFT JOIN website_pageviews wp ON ws.website_session_id = wp.website_session_id
WHERE ws.utm_source = 'gsearch'  AND ws.utm_campaign = 'nonbrand' AND ws.created_at BETWEEN '2012-06-19' AND '2012-07-28';

SELECT website_session_id, MAX(to_product) AS product_page, MAX(to_mr_fuzzy) AS mr_fuzzy_page, MAX(to_cart) AS cart_page, 
MAX(to_shipping) AS shipping_page, MAX(to_billing) AS billing_page ,MAX(to_thank_you) AS thank_you_page
FROM sessions_madeit_to_next_page GROUP BY 1;

SELECT fps.pageview_url, COUNT(DISTINCT CASE WHEN smnp.to_product = 1 THEN smnp.website_session_id ELSE NULL END) AS to_product,  
COUNT(DISTINCT CASE WHEN smnp.to_mr_fuzzy = 1 THEN smnp.website_session_id ELSE NULL END)  AS to_mr_fuzzy,
COUNT(DISTINCT CASE WHEN smnp.to_cart = 1 THEN smnp.website_session_id ELSE NULL END) AS to_cart,
COUNT(DISTINCT CASE WHEN smnp.to_shipping = 1 THEN smnp.website_session_id ELSE NULL END) AS to_shipping,
COUNT(DISTINCT CASE WHEN smnp.to_billing = 1 THEN smnp.website_session_id ELSE NULL END) AS to_billing,
COUNT(DISTINCT CASE WHEN smnp.to_thank_you = 1 THEN smnp.website_session_id ELSE NULL END)  AS to_thank_you
FROM first_page_sessions fps LEFT JOIN sessions_madeit_to_next_page smnp ON fps.website_session_id = smnp.website_session_id
GROUP BY 1;

-- AB Testing for Billing vs billing-2 pages - Avarage revenue per session, between 2012-09-10 and 2012-11-10.

SELECT `pageview_url` FROM `website_pageviews` GROUP BY 1;

CREATE TEMPORARY TABLE billing_pages_sessions
SELECT wp.pageview_url, wp.website_session_id, o.order_id, o.price_usd
FROM website_pageviews wp LEFT JOIN orders o ON o.website_session_id = wp.website_session_id
WHERE wp.pageview_url IN ('/billing-2','/billing') 
AND wp.created_at BETWEEN '2012-09-10' AND '2012-11-10';

SELECT pageview_url, COUNT(DISTINCT website_session_id) AS sessions, COUNT(DISTINCT order_id) AS orders, 
SUM(price_usd)/COUNT(DISTINCT website_session_id) AS revenue_per_billing_page
FROM billing_pages_sessions GROUP BY 1;

-- Session to order conversion rate for Homepage vs Lander-1page.

SELECT MIN(website_pageview_id) FROM website_pageviews WHERE pageview_url = '/lander-1';

SELECT `pageview_url` FROM `website_pageviews` GROUP BY 1;

CREATE TEMPORARY TABLE first_test_pageview
SELECT ws.website_session_id, MIN(website_pageview_id) AS min_pageview_id
FROM website_sessions ws
LEFT JOIN website_pageviews wp ON ws.website_session_id = wp.website_session_id
WHERE ws.utm_source = 'gsearch'  AND wp.website_pageview_id >= '23504' AND ws.utm_campaign = 'nonbrand' AND ws.created_at < '2012-07-28'
GROUP BY 1;

CREATE TEMPORARY TABLE nonbrand_test_sessions_w_landing_pages
SELECT ftp.website_session_id, wp.pageview_url
FROM first_test_pageview ftp LEFT JOIN website_pageviews wp ON ftp.website_session_id = wp.website_session_id
WHERE wp.pageview_url IN ('/lander-1','/home');

CREATE TEMPORARY TABLE nonbrand_test_orders_w_landing_pages
SELECT ntsl.website_session_id, ntsl.pageview_url, o.order_id
FROM nonbrand_test_sessions_w_landing_pages ntsl LEFT JOIN orders o ON ntsl.website_session_id = o.website_session_id;

SELECT pageview_url, COUNT(DISTINCT website_session_id) AS sessions, COUNT(DISTINCT order_id) AS orders, 
COUNT(DISTINCT order_id)/COUNT(DISTINCT website_session_id) AS session_to_order_conv_rt
FROM nonbrand_test_orders_w_landing_pages GROUP BY 1;

-- gsearch nonbrand campaign sessions using desktop vs mobile for data recorded before 2012-11-27.

SELECT utm_source, utm_campaign FROM website_sessions GROUP BY 1,2;
SELECT YEAR(ws.created_at) AS year, MONTH(ws.created_at) AS month, 
COUNT(DISTINCT CASE WHEN ws.device_type = 'mobile' THEN ws.website_session_id ELSE NULL END) AS mobile_gsearch_sessions, 
COUNT(DISTINCT CASE WHEN ws.device_type = 'desktop' THEN ws.website_session_id ELSE NULL END) AS desktop_gsearch_sessions,
COUNT(DISTINCT CASE WHEN ws.device_type = 'mobile' THEN o.order_id ELSE NULL END) AS mobile_gsearch_orders,
COUNT(DISTINCT CASE WHEN ws.device_type = 'desktop' THEN o.order_id ELSE NULL END) AS desktop_gsearch_orders
FROM website_sessions ws LEFT JOIN orders o ON ws.website_session_id = o.website_session_id 
WHERE ws.created_at < '2012-11-27' AND ws.utm_source = 'gsearch' AND ws.utm_campaign = 'nonbrand'
GROUP BY 1,2 order by 1,2;


-- Products bought together

SELECT * FROM orders;

SELECT o.order_id,  oi.product_id AS cross_sale_product, o.primary_product_id
FROM orders o LEFT JOIN order_items oi ON o.order_id = oi.order_id 
WHERE oi.is_primary_item = 0 AND o.created_at >= '2014-12-05' AND o.created_at < '2015-03-20'  ORDER BY 1,2;

SELECT primary_product_id, COUNT(DISTINCT order_id) AS orders, 
COUNT(DISTINCT CASE WHEN  cross_sale_product = 1 THEN order_id ELSE NULL END) AS product_1_cross_sale,
COUNT(DISTINCT CASE WHEN  cross_sale_product = 2 THEN order_id ELSE NULL END) AS product_2_cross_sale,
COUNT(DISTINCT CASE WHEN  cross_sale_product = 3 THEN order_id ELSE NULL END) AS product_3_cross_sale,
COUNT(DISTINCT CASE WHEN  cross_sale_product = 4 THEN order_id ELSE NULL END) AS product_4_cross_sale
FROM (SELECT o.order_id,  oi.product_id AS cross_sale_product, o.primary_product_id
FROM orders o LEFT JOIN order_items oi ON o.order_id = oi.order_id 
WHERE is_primary_item = 0 AND o.created_at >= '2014-12-05' AND o.created_at < '2015-03-20'  ORDER BY 1,2) AS cross_sale_orders GROUP BY 1 ORDER BY 1;


-- Sesson to order conversion rate and click through rate for all years divided by quorter.

SELECT pageview_url FROM website_pageviews GROUP BY 1;

CREATE TEMPORARY TABLE product_sessions						
SELECT created_at, website_session_id, pageview_url, website_pageview_id
FROM website_pageviews WHERE created_at < '2015-03-01' AND pageview_url = '/products';

CREATE TEMPORARY TABLE sessions_made_it_to_products_pages
SELECT ps.created_at, ps.website_session_id AS product_sessions, wp.website_session_id AS thru_product_sessions, ps.pageview_url AS product_url, 
wp.pageview_url AS thru_product_pages, wp.website_pageview_id AS thru_product_pageview_id,
 ps.website_pageview_id AS product_pageview_id
FROM product_sessions ps LEFT JOIN website_pageviews wp ON ps.website_session_id = wp.website_session_id AND ps.website_pageview_id < wp.website_pageview_id
AND wp.created_at < '2015-03-01' 
AND wp.pageview_url IN ('/the-original-mr-fuzzy','/the-forever-love-bear','/the-birthday-sugar-panda','/the-hudson-river-mini-bear');

SELECT YEAR(smp.created_at) AS year, MONTH(smp.created_at) AS month, COUNT(DISTINCT smp.product_sessions) AS total_product_sessions,
COUNT(DISTINCT CASE WHEN  smp.product_sessions = o.website_session_id THEN o.order_id ELSE NULL END)/ COUNT(DISTINCT smp.product_sessions) AS session_to_order_cov_rt, 
COUNT(DISTINCT smp.thru_product_sessions)/COUNT(DISTINCT smp.product_sessions) AS 	click_thru_rt 
FROM sessions_made_it_to_products_pages smp LEFT JOIN orders o ON smp.product_sessions = o.website_session_id AND o.created_at < '2015-03-01'
GROUP BY 1,2 ORDER BY 1,2;


-- Revenue per product 

SELECT o.order_id, oir.order_id, o.price_usd, oir.refund_amount_usd
FROM orders o
JOIN order_item_refunds oir ON oir.order_id = o.order_id;

SELECT pageview_url FROM website_pageviews WHERE created_at < '2015-01-01'GROUP BY 1;

SELECT YEAR(created_at) AS year, MONTH(created_at) AS month, 
SUM(CASE WHEN product_id = 1 THEN price_usd ELSE NULL END) AS mr_fuzzy_revenue,
SUM(CASE WHEN product_id = 1 THEN price_usd - cogs_usd ELSE NULL END) AS mr_fuzzy_margin,
SUM(CASE WHEN product_id = 2 THEN price_usd ELSE NULL END) AS love_bear_revenue,
SUM(CASE WHEN product_id = 2 THEN price_usd - cogs_usd ELSE NULL END) AS love_bear_margin,
SUM(CASE WHEN product_id = 3 THEN price_usd ELSE NULL END) AS suger_panda_revenue,
SUM(CASE WHEN product_id = 3 THEN price_usd - cogs_usd ELSE NULL END) AS suger_panda_margin,
SUM(CASE WHEN product_id = 4 THEN price_usd ELSE NULL END) AS mini_bear_revenue,
SUM(CASE WHEN product_id = 4 THEN price_usd - cogs_usd ELSE NULL END) AS mini_bear_margin,
COUNT(DISTINCT order_id) AS total_orders, SUM(price_usd) AS total_revenue 
FROM order_items  
WHERE created_at < '2015-03-01' GROUP BY 1,2 ORDER BY 1,2;


-- Marketing channels conversion rate

SELECT YEAR(ws.created_at) AS year, QUARTER(ws.created_at) AS quarter, 
COUNT(DISTINCT CASE WHEN ws.utm_source = 'gsearch' AND ws.utm_campaign = 'nonbrand' THEN o.order_id ELSE NULL END) /COUNT(DISTINCT CASE WHEN ws.utm_source = 'gsearch' AND ws.utm_campaign = 'nonbrand' THEN ws.website_session_id ELSE NULL END) AS gsearch_nonbrand_conv_rt,
COUNT(DISTINCT CASE WHEN ws.utm_source = 'bsearch' AND ws.utm_campaign = 'nonbrand' THEN o.order_id ELSE NULL END) /COUNT(DISTINCT CASE WHEN ws.utm_source = 'bsearch' AND ws.utm_campaign = 'nonbrand' THEN ws.website_session_id ELSE NULL END)AS bsearch_nonbrand_conv_rt,
COUNT(DISTINCT CASE WHEN ws.utm_campaign = 'brand' THEN o.order_id ELSE NULL END) /COUNT(DISTINCT CASE WHEN ws.utm_campaign = 'brand' THEN ws.website_session_id ELSE NULL END) AS brand_search_overall_conv_rt,
COUNT(DISTINCT CASE WHEN ws.utm_source IS NULL AND ws.utm_campaign IS NULL AND ws.http_referer IS NOT NULL THEN o.order_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN ws.utm_source IS NULL AND ws.utm_campaign IS NULL AND ws.http_referer IS NOT NULL THEN ws.website_session_id ELSE NULL END) AS organic_search_conv_rt,
COUNT(DISTINCT CASE WHEN ws.utm_source IS NULL AND ws.utm_campaign IS NULL AND ws.http_referer IS NULL THEN o.order_id ELSE NULL END) /COUNT(DISTINCT CASE WHEN ws.utm_source IS NULL AND ws.utm_campaign IS NULL AND ws.http_referer IS NULL THEN ws.website_session_id ELSE NULL END)AS direct_type_in_conv_rt
FROM website_sessions ws LEFT JOIN orders o ON ws.website_session_id = o.website_session_id 
WHERE ws.created_at < '2015-01-01' GROUP BY 1,2 ORDER BY 1,2;

-- Revenue per session and order

SELECT YEAR(ws.created_at) AS year, QUARTER(ws.created_at) AS quarter, COUNT(DISTINCT o.order_id)/COUNT(DISTINCT ws.website_session_id) AS session_to_order_conv_rt,
ROUND(SUM(o.price_usd)/COUNT(DISTINCT o.order_id),2) AS revnue_per_order, ROUND(SUM(o.price_usd)/COUNT(DISTINCT ws.website_session_id),2) AS revenue_per_session
FROM website_sessions ws LEFT JOIN orders o ON ws.website_session_id = o.website_session_id 
WHERE ws.created_at < '2015-01-01' GROUP BY 1,2 ORDER BY 1,2;

-- Overall revenue, orders, margin, net profit

CREATE TEMPORARY TABLE refuns_cogs
SELECT oir.order_item_id, oir.order_id, oir.refund_amount_usd, oi.cogs_usd
FROM order_item_refunds oir JOIN order_items oi ON oir.order_item_id = oi.order_item_id AND oir.refund_amount_usd = oi.price_usd 
AND oir.order_id = oi.order_id WHERE oi.created_at < '2015-01-01';

SELECT YEAR(ws.created_at) AS year, QUARTER(ws.created_at) AS quarter, COUNT(DISTINCT ws.website_session_id) AS sessions, 
COUNT(DISTINCT o.order_id) AS orders, SUM(o.price_usd) AS overall_orders_revenue, (SUM(o.price_usd) - SUM(o.cogs_usd)) AS margin, 
(SUM(o.price_usd) - SUM(oir.refund_amount_usd) - SUM(o.cogs_usd) + SUM(rc.cogs_usd)) AS clean_margin
FROM website_sessions ws LEFT JOIN orders o ON ws.website_session_id = o.website_session_id 
LEFT JOIN refuns_cogs rc ON o.order_id = rc.order_id
LEFT JOIN order_item_refunds oir ON oir.order_item_id = rc.order_item_id
WHERE ws.created_at < '2015-01-01' GROUP BY 1,2 ORDER BY 1,2;


-- Refund per product

SELECT YEAR(oi.created_at) AS year, MONTH(oi.created_at) AS month, 
COUNT(DISTINCT CASE WHEN oi.product_id = 1 THEN oi.order_item_id ELSE NULL END) AS p1_orders,
COUNT(DISTINCT CASE WHEN oir.order_item_refund_id IS NOT NULL AND oi.product_id = 1 THEN oir.order_item_id  ELSE NULL END)/
COUNT(DISTINCT CASE WHEN oi.product_id = 1  THEN oi.order_item_id ELSE NULL END) AS p1_refund_rt,
COUNT(DISTINCT CASE WHEN oi.product_id = 2 THEN oi.order_item_id ELSE NULL END) AS p2_orders,
COUNT(DISTINCT CASE WHEN oir.order_item_refund_id IS NOT NULL AND oi.product_id = 2 THEN oir.order_item_id  ELSE NULL END)/
COUNT(DISTINCT CASE WHEN oi.product_id = 2  THEN oi.order_item_id ELSE NULL END) AS p2_refund_rt,
COUNT(DISTINCT CASE WHEN oi.product_id = 3 THEN oi.order_item_id ELSE NULL END) AS p3_orders,
COUNT(DISTINCT CASE WHEN oir.order_item_refund_id IS NOT NULL AND oi.product_id = 3 THEN oir.order_item_id  ELSE NULL END)/
COUNT(DISTINCT CASE WHEN oi.product_id = 3  THEN oi.order_item_id ELSE NULL END) AS p3_refund_rt,
COUNT(DISTINCT CASE WHEN oi.product_id = 4 THEN oi.order_item_id ELSE NULL END) AS p4_orders,
COUNT(DISTINCT CASE WHEN oir.order_item_refund_id IS NOT NULL AND oi.product_id = 4 THEN oir.order_item_id  ELSE NULL END)/
COUNT(DISTINCT CASE WHEN oi.product_id = 4  THEN oi.order_item_id ELSE NULL END) AS p4_refund_rt
FROM order_items  oi LEFT JOIN order_item_refunds oir ON oi.order_item_id = oir.order_item_id 
WHERE oi.created_at < ' 2014-10-15'
GROUP BY 1,2;


-- love bear and mr fuzzy click through rate

CREATE TEMPORARY TABLE sessions_seen_product_page
 SELECT  website_session_id, website_pageview_id, pageview_url AS product_page_seen
  FROM website_pageviews 
 WHERE created_at > '2013-01-06' AND created_at < '2013-04-10' AND pageview_url IN ('/the-original-mr-fuzzy','/the-forever-love-bear');
 
 SELECT sessions_seen_product_page.product_page_seen, sessions_seen_product_page.website_session_id,
  CASE WHEN pageview_url= '/cart' THEN 1 ELSE 0 END AS cart_page, 
 CASE WHEN pageview_url= '/shipping' THEN 1 ELSE 0 END AS shipping_page,
 CASE WHEN pageview_url= '/billing-2' THEN 1 ELSE 0 END AS billing_page,
 CASE WHEN pageview_url= '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thank_you_page
 FROM sessions_seen_product_page 
 LEFT JOIN website_pageviews wp ON sessions_seen_product_page.website_session_id = wp.website_session_id 
 AND wp.website_pageview_id > sessions_seen_product_page.website_pageview_id ORDER BY 2, wp.created_at;
 
 CREATE TEMPORARY TABLE sessions_path_through_product_page1
 SELECT website_session_id, CASE WHEN product_page_seen = '/the-original-mr-fuzzy' THEN 'mr-fuzzy'
 WHEN product_page_seen = '/the-forever-love-bear' THEN 'love-bear' ELSE NULL END AS product_page, MAX(cart_page) AS cart, MAX(shipping_page) AS shipping, 
 MAX(billing_page) AS billing, MAX(thank_you_page) AS thank_you 
 FROM (SELECT sessions_seen_product_page.product_page_seen, sessions_seen_product_page.website_session_id,
  CASE WHEN pageview_url= '/cart' THEN 1 ELSE 0 END AS cart_page, 
 CASE WHEN pageview_url= '/shipping' THEN 1 ELSE 0 END AS shipping_page,
 CASE WHEN pageview_url= '/billing-2' THEN 1 ELSE 0 END AS billing_page,
 CASE WHEN pageview_url= '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thank_you_page
 FROM sessions_seen_product_page 
 LEFT JOIN website_pageviews wp ON sessions_seen_product_page.website_session_id = wp.website_session_id 
 AND wp.website_pageview_id > sessions_seen_product_page.website_pageview_id ORDER BY 2, wp.created_at) AS sessions_next_page_seen
 GROUP BY website_session_id, CASE WHEN product_page_seen = '/the-original-mr-fuzzy' THEN 'mr-fuzzy'
 WHEN product_page_seen = '/the-forever-love-bear' THEN 'love-bear' ELSE NULL END;
 
 SELECT product_page, COUNT(DISTINCT website_session_id) AS sessions, 
 COUNT(DISTINCT CASE WHEN cart = 1 THEN website_session_id ELSE NULL END) AS to_cart, 
 COUNT(DISTINCT CASE WHEN shipping = 1 THEN website_session_id ELSE NULL END) AS shipping,
 COUNT(DISTINCT CASE WHEN billing = 1 THEN website_session_id ELSE NULL END) AS billing,
 COUNT(DISTINCT CASE WHEN thank_you = 1 THEN website_session_id ELSE NULL END) AS thank_you
 FROM sessions_path_through_product_page1 GROUP BY product_page ;
 
 -- love bear and mr fuzzy conversion rate
 
 SELECT product_page,  
 COUNT(DISTINCT CASE WHEN cart = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT website_session_id) AS product_click_through, 
 COUNT(DISTINCT CASE WHEN shipping = 1 THEN website_session_id ELSE NULL END)/ COUNT(DISTINCT CASE WHEN cart = 1 THEN website_session_id ELSE NULL END) AS cart_click_through,
 COUNT(DISTINCT CASE WHEN billing = 1 THEN website_session_id ELSE NULL END)/ COUNT(DISTINCT CASE WHEN shipping = 1 THEN website_session_id ELSE NULL END) AS shipping_click_through,
 COUNT(DISTINCT CASE WHEN thank_you = 1 THEN website_session_id ELSE NULL END)/ COUNT(DISTINCT CASE WHEN billing = 1 THEN website_session_id ELSE NULL END) AS billing_click_through
 FROM sessions_path_through_product_page1 GROUP BY product_page ;

