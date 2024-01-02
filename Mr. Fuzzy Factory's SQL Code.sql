-- Revenue per product 

SELECT 
    o.order_id, oir.order_id, o.price_usd, oir.refund_amount_usd
FROM
    orders o
        JOIN
    order_item_refunds oir ON oir.order_id = o.order_id;

CREATE TEMPORARY TABLE products
SELECT 
    pageview_url, website_session_id, created_at
FROM
    website_pageviews
WHERE
    created_at < '2015-01-01'
        AND pageview_url IN ('/the-original-mr-fuzzy' , '/the-forever-love-bear',
        '/the-birthday-sugar-panda',
        '/the-hudson-river-mini-bear')
GROUP BY 1 , 2 , 3;

CREATE TEMPORARY TABLE product_revenue
SELECT 
    YEAR(oi.created_at) AS year,
    MONTH(oi.created_at) AS month,
    p.website_session_id,
    SUM(CASE
        WHEN p.pageview_url = '/the-original-mr-fuzzy' THEN oi.price_usd
        ELSE NULL
    END) AS mr_fuzzy_revenue,
    SUM(CASE
        WHEN oi.product_id = 1 THEN oi.price_usd - oi.cogs_usd
        ELSE NULL
    END) AS mr_fuzzy_margin,
    SUM(CASE
        WHEN p.pageview_url = '/the-forever-love-bear' THEN oi.price_usd
        ELSE NULL
    END) AS love_bear_revenue,
    SUM(CASE
        WHEN oi.product_id = 2 THEN oi.price_usd - oi.cogs_usd
        ELSE NULL
    END) AS love_bear_margin,
    SUM(CASE
        WHEN p.pageview_url = '/the-birthday-sugar-panda' THEN oi.price_usd
        ELSE NULL
    END) AS suger_panda_revenue,
    SUM(CASE
        WHEN oi.product_id = 3 THEN oi.price_usd - oi.cogs_usd
        ELSE NULL
    END) AS suger_panda_margin,
    SUM(CASE
        WHEN p.pageview_url = '/the-hudson-river-mini-bear' THEN oi.price_usd
        ELSE NULL
    END) AS mini_bear_revenue,
    SUM(CASE
        WHEN oi.product_id = 4 THEN oi.price_usd - oi.cogs_usd
        ELSE NULL
    END) AS mini_bear_margin,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    SUM(oi.price_usd) AS total_revenue
FROM
    order_items oi
        JOIN
    orders o ON o.order_id = oi.order_id
        JOIN
    products p ON o.website_session_id = p.website_session_id
WHERE
    oi.created_at < '2015-01-01'
GROUP BY 1 , 2 , 3
ORDER BY 1 , 2 , 3;

SELECT 
    (CASE
        WHEN p.pageview_url = '/the-original-mr-fuzzy' THEN 'mr-fuzzy'
        WHEN p.pageview_url = '/the-forever-love-bear' THEN 'love-bear'
        WHEN p.pageview_url = '/the-birthday-sugar-panda' THEN 'sugar-panda'
        WHEN p.pageview_url = '/the-hudson-river-mini-bear' THEN 'mini-bear'
        ELSE NULL
    END) AS products,
    pr.year,
    SUM(CASE
        WHEN p.pageview_url = '/the-original-mr-fuzzy' THEN pr.mr_fuzzy_margin
        WHEN p.pageview_url = '/the-forever-love-bear' THEN pr.love_bear_margin
        WHEN p.pageview_url = '/the-birthday-sugar-panda' THEN pr.suger_panda_margin
        WHEN p.pageview_url = '/the-hudson-river-mini-bear' THEN pr.mini_bear_margin
        ELSE NULL
    END) AS products_margin
FROM
    product_revenue pr
        LEFT JOIN
    products p ON p.website_session_id = pr.website_session_id
GROUP BY 1 , 2
ORDER BY 1 , 2;


-- Margin per product

CREATE TEMPORARY TABLE refuns_cogs
SELECT 
    oir.order_item_id,
    oir.order_id,
    oir.refund_amount_usd,
    oi.cogs_usd
FROM
    order_item_refunds oir
        JOIN
    order_items oi ON oir.order_item_id = oi.order_item_id
        AND oir.refund_amount_usd = oi.price_usd
        AND oir.order_id = oi.order_id
WHERE
    oi.created_at < '2015-01-01';

SELECT 
    YEAR(ws.created_at) AS year,
    QUARTER(ws.created_at) AS quarter,
    COUNT(DISTINCT ws.website_session_id) AS sessions,
    COUNT(DISTINCT o.order_id) AS orders,
    SUM(o.price_usd) AS overall_orders_revenue,
    (SUM(o.price_usd) - SUM(o.cogs_usd)) AS margin,
    (SUM(o.price_usd) - SUM(oir.refund_amount_usd) - SUM(o.cogs_usd) + SUM(rc.cogs_usd)) AS clean_margin
FROM
    website_sessions ws
        LEFT JOIN
    orders o ON ws.website_session_id = o.website_session_id
        LEFT JOIN
    refuns_cogs rc ON o.order_id = rc.order_id
        LEFT JOIN
    order_item_refunds oir ON oir.order_item_id = rc.order_item_id
WHERE
    ws.created_at < '2015-01-01'
GROUP BY 1 , 2
ORDER BY 1 , 2;


-- Products cross sale

SELECT 
    *
FROM
    orders;

SELECT 
    o.order_id,
    oi.product_id AS cross_sale_product,
    o.primary_product_id
FROM
    orders o
        LEFT JOIN
    order_items oi ON o.order_id = oi.order_id
WHERE
    oi.is_primary_item = 0
        AND o.created_at >= '2014-12-05'
        AND o.created_at < '2015-03-20'
ORDER BY 1 , 2;

SELECT 
    primary_product_id,
    COUNT(DISTINCT order_id) AS orders,
    COUNT(DISTINCT CASE
            WHEN cross_sale_product = 1 THEN order_id
            ELSE NULL
        END) AS product_1_cross_sale,
    COUNT(DISTINCT CASE
            WHEN cross_sale_product = 2 THEN order_id
            ELSE NULL
        END) AS product_2_cross_sale,
    COUNT(DISTINCT CASE
            WHEN cross_sale_product = 3 THEN order_id
            ELSE NULL
        END) AS product_3_cross_sale,
    COUNT(DISTINCT CASE
            WHEN cross_sale_product = 4 THEN order_id
            ELSE NULL
        END) AS product_4_cross_sale
FROM
    (SELECT 
        o.order_id,
            oi.product_id AS cross_sale_product,
            o.primary_product_id
    FROM
        orders o
    LEFT JOIN order_items oi ON o.order_id = oi.order_id
    WHERE
        is_primary_item = 0
            AND o.created_at >= '2015-01-01'
    ORDER BY 1 , 2) AS cross_sale_orders
GROUP BY 1
ORDER BY 1;

SELECT 
    o.primary_product_id, oi.product_id, wp.pageview_url
FROM
    orders o
        LEFT JOIN
    order_items oi ON o.order_id = oi.order_id
        LEFT JOIN
    website_pageviews wp ON wp.website_session_id = o.website_session_id
WHERE
    oi.product_id = '3';


-- Marketing channels conversion rate

CREATE TEMPORARY TABLE channel_source_conv_rt
SELECT 
    YEAR(ws.created_at) AS year,
    QUARTER(ws.created_at) AS quarter,
    COUNT(DISTINCT CASE
            WHEN
                ws.utm_source = 'gsearch'
                    AND ws.utm_campaign = 'nonbrand'
            THEN
                o.order_id
            ELSE NULL
        END) / COUNT(DISTINCT CASE
            WHEN
                ws.utm_source = 'gsearch'
                    AND ws.utm_campaign = 'nonbrand'
            THEN
                ws.website_session_id
            ELSE NULL
        END) AS gsearch_nonbrand_conv_rt,
    COUNT(DISTINCT CASE
            WHEN
                ws.utm_source = 'bsearch'
                    AND ws.utm_campaign = 'nonbrand'
            THEN
                o.order_id
            ELSE NULL
        END) / COUNT(DISTINCT CASE
            WHEN
                ws.utm_source = 'bsearch'
                    AND ws.utm_campaign = 'nonbrand'
            THEN
                ws.website_session_id
            ELSE NULL
        END) AS bsearch_nonbrand_conv_rt,
    COUNT(DISTINCT CASE
            WHEN ws.utm_campaign = 'brand' THEN o.order_id
            ELSE NULL
        END) / COUNT(DISTINCT CASE
            WHEN ws.utm_campaign = 'brand' THEN ws.website_session_id
            ELSE NULL
        END) AS brand_search_overall_conv_rt,
    COUNT(DISTINCT CASE
            WHEN
                ws.utm_source IS NULL
                    AND ws.utm_campaign IS NULL
                    AND ws.http_referer IS NOT NULL
            THEN
                o.order_id
            ELSE NULL
        END) / COUNT(DISTINCT CASE
            WHEN
                ws.utm_source IS NULL
                    AND ws.utm_campaign IS NULL
                    AND ws.http_referer IS NOT NULL
            THEN
                ws.website_session_id
            ELSE NULL
        END) AS organic_search_conv_rt,
    COUNT(DISTINCT CASE
            WHEN
                ws.utm_source IS NULL
                    AND ws.utm_campaign IS NULL
                    AND ws.http_referer IS NULL
            THEN
                o.order_id
            ELSE NULL
        END) / COUNT(DISTINCT CASE
            WHEN
                ws.utm_source IS NULL
                    AND ws.utm_campaign IS NULL
                    AND ws.http_referer IS NULL
            THEN
                ws.website_session_id
            ELSE NULL
        END) AS direct_type_in_conv_rt
FROM
    website_sessions ws
        LEFT JOIN
    orders o ON ws.website_session_id = o.website_session_id
WHERE
    ws.created_at < '2015-01-01'
GROUP BY 1 , 2
ORDER BY 1 , 2;

SELECT 
    (CASE
        WHEN
            ws.utm_source = 'gsearch'
                AND ws.utm_campaign = 'nonbrand'
        THEN
            'gsearch_nonbrand'
        WHEN
            ws.utm_source = 'bsearch'
                AND ws.utm_campaign = 'nonbrand'
        THEN
            'bsearch_nonbrand'
        WHEN ws.utm_campaign = 'brand' THEN 'brand_search'
        WHEN
            ws.utm_source IS NULL
                AND ws.utm_campaign IS NULL
                AND ws.http_referer IS NOT NULL
        THEN
            'organic_search'
        WHEN
            ws.utm_source IS NULL
                AND ws.utm_campaign IS NULL
                AND ws.http_referer IS NULL
        THEN
            'direct_type_in'
        ELSE NULL
    END) AS channel_source,
    YEAR(ws.created_at) AS year,
    ROUND(AVG(CASE
                WHEN
                    ws.utm_source = 'gsearch'
                        AND ws.utm_campaign = 'nonbrand'
                THEN
                    channel_source.gsearch_nonbrand_conv_rt
                WHEN
                    ws.utm_source = 'bsearch'
                        AND ws.utm_campaign = 'nonbrand'
                THEN
                    channel_source.bsearch_nonbrand_conv_rt
                WHEN ws.utm_campaign = 'brand' THEN channel_source.brand_search_overall_conv_rt
                WHEN
                    ws.utm_source IS NULL
                        AND ws.utm_campaign IS NULL
                        AND ws.http_referer IS NOT NULL
                THEN
                    channel_source.organic_search_conv_rt
                WHEN
                    ws.utm_source IS NULL
                        AND ws.utm_campaign IS NULL
                        AND ws.http_referer IS NULL
                THEN
                    channel_source.direct_type_in_conv_rt
                ELSE NULL
            END),
            2) AS channel_source_conv_rt
FROM
    (SELECT 
        YEAR(ws.created_at) AS year,
            QUARTER(ws.created_at) AS quarter,
            COUNT(DISTINCT CASE
                WHEN
                    ws.utm_source = 'gsearch'
                        AND ws.utm_campaign = 'nonbrand'
                THEN
                    o.order_id
                ELSE NULL
            END) / COUNT(DISTINCT CASE
                WHEN
                    ws.utm_source = 'gsearch'
                        AND ws.utm_campaign = 'nonbrand'
                THEN
                    ws.website_session_id
                ELSE NULL
            END) AS gsearch_nonbrand_conv_rt,
            COUNT(DISTINCT CASE
                WHEN
                    ws.utm_source = 'bsearch'
                        AND ws.utm_campaign = 'nonbrand'
                THEN
                    o.order_id
                ELSE NULL
            END) / COUNT(DISTINCT CASE
                WHEN
                    ws.utm_source = 'bsearch'
                        AND ws.utm_campaign = 'nonbrand'
                THEN
                    ws.website_session_id
                ELSE NULL
            END) AS bsearch_nonbrand_conv_rt,
            COUNT(DISTINCT CASE
                WHEN ws.utm_campaign = 'brand' THEN o.order_id
                ELSE NULL
            END) / COUNT(DISTINCT CASE
                WHEN ws.utm_campaign = 'brand' THEN ws.website_session_id
                ELSE NULL
            END) AS brand_search_overall_conv_rt,
            COUNT(DISTINCT CASE
                WHEN
                    ws.utm_source IS NULL
                        AND ws.utm_campaign IS NULL
                        AND ws.http_referer IS NOT NULL
                THEN
                    o.order_id
                ELSE NULL
            END) / COUNT(DISTINCT CASE
                WHEN
                    ws.utm_source IS NULL
                        AND ws.utm_campaign IS NULL
                        AND ws.http_referer IS NOT NULL
                THEN
                    ws.website_session_id
                ELSE NULL
            END) AS organic_search_conv_rt,
            COUNT(DISTINCT CASE
                WHEN
                    ws.utm_source IS NULL
                        AND ws.utm_campaign IS NULL
                        AND ws.http_referer IS NULL
                THEN
                    o.order_id
                ELSE NULL
            END) / COUNT(DISTINCT CASE
                WHEN
                    ws.utm_source IS NULL
                        AND ws.utm_campaign IS NULL
                        AND ws.http_referer IS NULL
                THEN
                    ws.website_session_id
                ELSE NULL
            END) AS direct_type_in_conv_rt
    FROM
        website_sessions ws
    LEFT JOIN orders o ON ws.website_session_id = o.website_session_id
    WHERE
        ws.created_at < '2015-01-01'
    GROUP BY 1 , 2
    ORDER BY 1 , 2) AS channel_source
        LEFT JOIN
    website_sessions ws ON YEAR(ws.created_at) = channel_source.year
        AND QUARTER(ws.created_at) = channel_source.quarter
GROUP BY 1 , 2
ORDER BY 1 , 2;


-- "gsearch" nonbrand marketing campaign sessions using desktop vs mobile device.

SELECT utm_source, utm_campaign FROM website_sessions GROUP BY 1,2;

SELECT 
    YEAR(ws.created_at) AS year,
    MONTH(ws.created_at) AS month,
    COUNT(DISTINCT CASE
            WHEN ws.device_type = 'mobile' THEN ws.website_session_id
            ELSE NULL
        END) AS mobile_gsearch_sessions,
    COUNT(DISTINCT CASE
            WHEN ws.device_type = 'desktop' THEN ws.website_session_id
            ELSE NULL
        END) AS desktop_gsearch_sessions,
    COUNT(DISTINCT CASE
            WHEN ws.device_type = 'mobile' THEN o.order_id
            ELSE NULL
        END) AS mobile_gsearch_orders,
    COUNT(DISTINCT CASE
            WHEN ws.device_type = 'desktop' THEN o.order_id
            ELSE NULL
        END) AS desktop_gsearch_orders
FROM
    website_sessions ws
        LEFT JOIN
    orders o ON ws.website_session_id = o.website_session_id
WHERE
    ws.created_at < '2015-01-01'
        AND ws.utm_source = 'gsearch'
        AND ws.utm_campaign = 'nonbrand'
GROUP BY 1 , 2
ORDER BY 1 , 2;


SELECT 
    YEAR(ws.created_at) AS year,
    (CASE
        WHEN ws.device_type = 'mobile' THEN 'mobile'
        WHEN ws.device_type = 'desktop' THEN 'desktop'
        ELSE NULL
    END) AS device_type,
    COUNT(DISTINCT CASE
            WHEN ws.device_type = 'mobile' THEN ws.website_session_id
            WHEN ws.device_type = 'desktop' THEN ws.website_session_id
            ELSE NULL
        END) AS sessions,
    COUNT(DISTINCT CASE
            WHEN ws.device_type = 'mobile' AND o.order_id THEN o.order_id
            WHEN
                ws.device_type = 'desktop'
                    AND o.order_id
            THEN
                o.order_id
            ELSE NULL
        END) AS orders
FROM
    website_sessions ws
        LEFT JOIN
    orders o ON ws.website_session_id = o.website_session_id
WHERE
    ws.created_at < '2015-01-01'
        AND ws.utm_source = 'gsearch'
        AND ws.utm_campaign = 'nonbrand'
GROUP BY 1 , 2
ORDER BY 1 , 2;

SELECT*FROM website_sessions;


-- AB Testing for "Home" vs "Lander-1" pages between the dates 2012-06-19 and 2012-07-28, when the factory added the new "Lander-1" page.

USE mavenfuzzyfactory;
SELECT 
    `pageview_url`
FROM
    `website_pageviews`
GROUP BY 1;

CREATE TEMPORARY TABLE first_page_sessions
SELECT 
    wp.pageview_url, ws.website_session_id
FROM
    website_sessions ws
        LEFT JOIN
    website_pageviews wp ON ws.website_session_id = wp.website_session_id
WHERE
    ws.utm_source = 'gsearch'
        AND ws.utm_campaign = 'nonbrand'
        AND wp.pageview_url IN ('/home' , '/lander-1')
        AND ws.created_at BETWEEN '2012-06-19' AND '2012-07-28';

CREATE TEMPORARY TABLE sessions_madeit_to_next_page
SELECT 
    ws.website_session_id,
    CASE
        WHEN wp.pageview_url = '/products' THEN 1
        ELSE NULL
    END AS to_product,
    CASE
        WHEN wp.pageview_url = '/the-original-mr-fuzzy' THEN 1
        ELSE NULL
    END AS to_mr_fuzzy,
    CASE
        WHEN wp.pageview_url = '/cart' THEN 1
        ELSE NULL
    END AS to_cart,
    CASE
        WHEN wp.pageview_url = '/shipping' THEN 1
        ELSE NULL
    END AS to_shipping,
    CASE
        WHEN wp.pageview_url = '/billing' THEN 1
        ELSE NULL
    END AS to_billing,
    CASE
        WHEN wp.pageview_url = '/thank-you-for-your-order' THEN 1
        ELSE NULL
    END AS to_thank_you
FROM
    website_sessions ws
        LEFT JOIN
    website_pageviews wp ON ws.website_session_id = wp.website_session_id
WHERE
    ws.utm_source = 'gsearch'
        AND ws.utm_campaign = 'nonbrand'
        AND ws.created_at BETWEEN '2012-06-19' AND '2012-07-28';

SELECT 
    website_session_id,
    MAX(to_product) AS product_page,
    MAX(to_mr_fuzzy) AS mr_fuzzy_page,
    MAX(to_cart) AS cart_page,
    MAX(to_shipping) AS shipping_page,
    MAX(to_billing) AS billing_page,
    MAX(to_thank_you) AS thank_you_page
FROM
    sessions_madeit_to_next_page
GROUP BY 1;

SELECT 
    fps.pageview_url,
    COUNT(DISTINCT CASE
            WHEN smnp.to_product = 1 THEN smnp.website_session_id
            ELSE NULL
        END) AS to_product,
    COUNT(DISTINCT CASE
            WHEN smnp.to_mr_fuzzy = 1 THEN smnp.website_session_id
            ELSE NULL
        END) AS to_mr_fuzzy,
    COUNT(DISTINCT CASE
            WHEN smnp.to_cart = 1 THEN smnp.website_session_id
            ELSE NULL
        END) AS to_cart,
    COUNT(DISTINCT CASE
            WHEN smnp.to_shipping = 1 THEN smnp.website_session_id
            ELSE NULL
        END) AS to_shipping,
    COUNT(DISTINCT CASE
            WHEN smnp.to_billing = 1 THEN smnp.website_session_id
            ELSE NULL
        END) AS to_billing,
    COUNT(DISTINCT CASE
            WHEN smnp.to_thank_you = 1 THEN smnp.website_session_id
            ELSE NULL
        END) AS to_thank_you
FROM
    first_page_sessions fps
        LEFT JOIN
    sessions_madeit_to_next_page smnp ON fps.website_session_id = smnp.website_session_id
GROUP BY 1;

SELECT 
    (CASE
        WHEN smnp.to_product = 1 THEN 'to_product'
        WHEN smnp.to_mr_fuzzy = 1 THEN 'to_mr_fuzzy'
        WHEN smnp.to_cart = 1 THEN 'to_cart'
        WHEN smnp.to_shipping = 1 THEN 'to_shipping'
        WHEN smnp.to_billing = 1 THEN 'to_billing'
        WHEN smnp.to_thank_you = 1 THEN 'to_thank_you'
        ELSE NULL
    END) AS click_to_next_page,
    fps.pageview_url,
    COUNT(DISTINCT CASE
            WHEN
                wp.pageview_url = '/products'
                    AND fps.pageview_url = '/home'
            THEN
                smnp.website_session_id
            WHEN
                wp.pageview_url = '/the-original-mr-fuzzy'
                    AND fps.pageview_url = '/home'
            THEN
                smnp.website_session_id
            WHEN
                wp.pageview_url = '/cart'
                    AND fps.pageview_url = '/home'
            THEN
                smnp.website_session_id
            WHEN
                wp.pageview_url = '/shipping'
                    AND fps.pageview_url = '/home'
            THEN
                smnp.website_session_id
            WHEN
                wp.pageview_url = '/billing'
                    AND fps.pageview_url = '/home'
            THEN
                smnp.website_session_id
            WHEN
                wp.pageview_url = '/thank-you-for-your-order'
                    AND fps.pageview_url = '/home'
            THEN
                smnp.website_session_id
            WHEN
                wp.pageview_url = '/products'
                    AND fps.pageview_url = '/lander-1'
            THEN
                smnp.website_session_id
            WHEN
                wp.pageview_url = '/the-original-mr-fuzzy'
                    AND fps.pageview_url = '/lander-1'
            THEN
                smnp.website_session_id
            WHEN
                wp.pageview_url = '/cart'
                    AND fps.pageview_url = '/lander-1'
            THEN
                smnp.website_session_id
            WHEN
                wp.pageview_url = '/shipping'
                    AND fps.pageview_url = '/lander-1'
            THEN
                smnp.website_session_id
            WHEN
                wp.pageview_url = '/billing'
                    AND fps.pageview_url = '/lander-1'
            THEN
                smnp.website_session_id
            WHEN
                wp.pageview_url = '/thank-you-for-your-order'
                    AND fps.pageview_url = '/lander-1'
            THEN
                smnp.website_session_id
            ELSE NULL
        END) AS sessions_to_next_page
FROM
    website_pageviews wp
        JOIN
    first_page_sessions fps ON fps.website_session_id = wp.website_session_id
        JOIN
    sessions_madeit_to_next_page smnp ON smnp.website_session_id = wp.website_session_id
GROUP BY 2 , 1
ORDER BY 3 DESC;
