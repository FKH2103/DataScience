SELECT COUNT(*) FROM zomato_raw;

SELECT COUNT(*) FROM locations;

SELECT COUNT(*) FROM restaurants;
SELECT *
FROM zomato_raw
LIMIT 10;
SELECT *
FROM locations
LIMIT 10;
SELECT *
FROM restaurants
LIMIT 10;
SELECT *
FROM services_metrics
LIMIT 10;
SELECT
    r.restaurant_id,
    r.name,
    r.phone,
    r.rest_type,

    l.address,
    l.neighborhood,
    l.city,

    s.rate,
    s.votes,
    s.approx_cost,
    s.listed_in_type,
    s.cuisines,       
    s.menu_item

FROM restaurants r

JOIN locations l
ON r.location_id = l.location_id
JOIN services_metrics s
ON r.restaurant_id = s.restaurant_id

LIMIT 20;
SELECT DISTINCT rate
FROM services_metrics
ORDER BY rate;
SELECT DISTINCT approx_cost
FROM services_metrics
ORDER BY approx_cost
LIMIT 20;
SELECT
    name,
    COUNT(*) as branch_count
FROM restaurants
GROUP BY name
HAVING COUNT(*) > 1
ORDER BY branch_count DESC
LIMIT 20;
SELECT COUNT(*)
FROM restaurants
WHERE phone IS NULL;
SELECT COUNT(*)
FROM services_metrics
WHERE rate IS NULL;
SELECT
    r.name,
    l.city,
    s.rate,
    s.votes,
    s.approx_cost,
    s.listed_in_type

FROM restaurants r

JOIN locations l
ON r.location_id = l.location_id

JOIN services_metrics s
ON r.restaurant_id = s.restaurant_id

WHERE r.name LIKE '%Domino%'

LIMIT 20;
SELECT *
FROM zomato_raw
WHERE name LIKE '%Domino%'
LIMIT 20;
SELECT
    r.restaurant_id,
    r.name,
    l.city,
    s.rate,
    s.listed_in_type
FROM restaurants r
JOIN locations l
ON r.location_id = l.location_id
JOIN services_metrics s
ON r.restaurant_id = s.restaurant_id
WHERE r.name LIKE '%Domino%'
LIMIT 20;