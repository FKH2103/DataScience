USE ashpaz_db;


-- Query 1: Total restaurants and average cost for Delivery
SELECT 
    COUNT(DISTINCT restaurant_id) AS total_delivery_restaurants,
    ROUND(AVG(approx_cost), 2) AS average_delivery_cost
FROM services_metrics
WHERE listed_in_type = 'Delivery';



-- Query 2: Impact of online orders on pricing and votes per city
SELECT 
    l.city, 
    s.online_order, 

    ROUND(AVG(s.approx_cost), 2) AS avg_approx_cost, 
    SUM(COALESCE(s.votes,0)) AS total_votes

FROM locations l
JOIN restaurants r 
ON l.location_id = r.location_id

JOIN services_metrics s 
ON r.restaurant_id = s.restaurant_id

GROUP BY l.city, s.online_order
ORDER BY l.city ASC, s.online_order DESC;


-- Query 3: Find top-tier dining neighborhoods
-- Filtering for average rating > 4.2 and strictly >= 50 unique restaurants
SELECT 
    l.neighborhood, 
    COUNT(DISTINCT r.restaurant_id) AS restaurant_count, 
    ROUND(AVG(s.rate), 2) AS avg_rating
FROM locations l
JOIN restaurants r ON l.location_id = r.location_id
JOIN services_metrics s ON r.restaurant_id = s.restaurant_id
GROUP BY l.neighborhood
HAVING avg_rating > 4.2 AND restaurant_count >= 50
ORDER BY avg_rating DESC;

-- View neighborhood stats without HAVING filter for troubleshooting
-- Using DISTINCT to count unique physical restaurants, not services
SELECT 
    l.neighborhood, 
    COUNT(DISTINCT r.restaurant_id) AS restaurant_count, 
    ROUND(AVG(s.rate), 2) AS avg_rating
FROM locations l
JOIN restaurants r ON l.location_id = r.location_id
JOIN services_metrics s ON r.restaurant_id = s.restaurant_id
GROUP BY l.neighborhood
ORDER BY restaurant_count DESC
LIMIT 10;


-- Query 4: Pricing tier dashboard
SELECT 
    l.city,
    CASE 
        WHEN s.approx_cost <= 500 
            THEN 'Budget'
        WHEN s.approx_cost BETWEEN 501 AND 999 
            THEN 'Mid-Range'
        ELSE 'Premium'
    END AS pricing_tier,

    COUNT(DISTINCT r.restaurant_id) AS restaurant_count,
    ROUND(AVG(s.rate), 2) AS avg_rating

FROM locations l
JOIN restaurants r 
ON l.location_id = r.location_id

JOIN services_metrics s 
ON r.restaurant_id = s.restaurant_id

GROUP BY l.city, pricing_tier
ORDER BY l.city ASC, restaurant_count DESC;