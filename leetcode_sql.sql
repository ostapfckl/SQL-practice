-- LeetCode 577 - Employee Bonus
-- Topic: LEFT JOIN
-- Idea: keep employees without bonuses and filter bonus < 1000 or NULL
-- My Solution
SELECT 
    e.name,
    b.bonus 
FROM Employee e
LEFT JOIN Bonus b 
    ON e.empId = b.empId
WHERE b.bonus < 1000 
   OR b.bonus IS NULL;
--====================================================================

-- LeetCode 620 - Not Boring Movies
-- Pattern: Filtering 
-- Idea: Filter movies with odd id using id % 2 = 1, exclude description = 'boring', then sort by rating descending
-- My Solution
SELECT *
FROM Cinema
WHERE id % 2 = 1
  AND description <> 'boring'
ORDER BY rating DESC

-- ==================================================================
-- LeetCode 1251 - Average Selling Price
-- Pattern: JOIN + Weighted Average
-- Idea: Join Prices with UnitsSold by product_id and purchase_date within the price interval, 
-- compute weighted average using SUM(price * units) / SUM(units), handle products without sales using LEFT JOIN and COALESCE
-- My Solution
SELECT
    p.product_id,
    ROUND(COALESCE(SUM(p.price * u.units) / SUM(u.units), 0), 2) AS average_price
FROM Prices p
LEFT JOIN UnitsSold u
    ON p.product_id = u.product_id
   AND u.purchase_date BETWEEN p.start_date AND p.end_date
GROUP BY p.product_id

-- ================================================================
-- LeetCode 1075 - Project Employees I
-- Pattern: JOIN + GROUP BY + Aggregation
-- Idea: Join Project with Employee by employee_id and compute average experience per project. 
-- My solution uses SUM/COUNT, while the best solution uses AVG().
-- My Solution
SELECT 
    p.project_id,
    ROUND(SUM(e.experience_years) / COUNT(*), 2) AS average_years
FROM Project p
LEFT JOIN Employee e 
    ON p.employee_id = e.employee_id
GROUP BY p.project_id

-- Best Solution
SELECT
    p.project_id,
    ROUND(AVG(e.experience_years), 2) AS average_years
FROM Project p
JOIN Employee e
    ON p.employee_id = e.employee_id
GROUP BY p.project_id

-- ==============================================================
-- LeetCode 1633 - Percentage of Users Attended a Contest
-- Pattern: GROUP BY + Aggregation + Subquery
-- Idea: Count users registered in each contest and divide by the total number of users, multiply by 100 and round to 2 decimals
-- My Solution
SELECT 
    r.contest_id,
    ROUND(
        COUNT(r.user_id) /
        (SELECT COUNT(DISTINCT user_id) FROM Users) * 100.0,
        2
    ) AS percentage
FROM Register r
LEFT JOIN Users u 
    ON r.user_id = u.user_id
GROUP BY r.contest_id
ORDER BY percentage DESC, r.contest_id

-- Best Solution
-- Changes:
-- 1. Removed unnecessary LEFT JOIN with Users (data not used in SELECT).
-- 2. Used COUNT(*) instead of COUNT(user_id) (simpler, same result).
SELECT
    contest_id,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM Users), 2) AS percentage
FROM Register
GROUP BY contest_id
ORDER BY percentage DESC, contest_id

-- ==============================================================

-- LeetCode 1211 - Queries Quality and Percentage
-- Pattern: GROUP BY + AVG + CASE WHEN
-- Idea: Group by query_name, calculate quality as average of rating / position, and calculate poor query percentage as average of rows with rating < 3 multiplied by 100
-- My Solution
SELECT 
    query_name,
    ROUND(AVG(rating / position), 2) AS quality,
    ROUND(AVG(CASE WHEN rating < 3 THEN 1 ELSE 0 END) * 100, 2) AS poor_query_percentage
FROM Queries
GROUP BY query_name
-- ==============================================================
-- LeetCode 1193 - Monthly Transactions I
-- Pattern: GROUP BY + Conditional Aggregation + Date Formatting
-- Idea: Group by month and country, count all transactions and sum all amounts, 
-- then use CASE WHEN to count only approved transactions and sum only approved amounts
-- My Solution
SELECT
    TO_CHAR(trans_date, 'YYYY-MM') AS month,
    country,
    COUNT(id) AS trans_count,
    SUM(CASE WHEN state = 'approved' THEN 1 ELSE 0 END) AS approved_count,
    SUM(amount) AS trans_total_amount,
    SUM(CASE WHEN state = 'approved' THEN amount ELSE 0 END) AS approved_total_amount
FROM Transactions
GROUP BY TO_CHAR(trans_date, 'YYYY-MM'), country

-- ===============================================================
-- LeetCode 1174 - Immediate Food Delivery II
-- Pattern: Window Function + Filtering + AVG + CASE WHEN
-- Idea: Find each customer's first order using MIN() OVER(PARTITION BY customer_id), 
-- keep only first orders, then calculate the percentage of immediate deliveries
-- My Solution
SELECT
    ROUND(AVG(CASE WHEN t.status = 'immediate' THEN 1 ELSE 0 END) * 100, 2) AS immediate_percentage
FROM (
    SELECT
        delivery_id,
        customer_id,
        order_date,
        customer_pref_delivery_date,
        MIN(order_date) OVER(PARTITION BY customer_id) AS firs_del,
        CASE
            WHEN order_date = customer_pref_delivery_date THEN 'immediate'
            ELSE 'scheduled'
        END AS status
    FROM Delivery
) t
WHERE order_date = firs_del

-- ===============================================================
-- LeetCode 1141 - User Activity for the Past 30 Days I
-- Pattern: Aggregation + Date filtering
-- Idea: Filter the last 30 days ending 2019-07-27 (inclusive), then group by activity_date and count distinct users to get daily active users.
-- My Solution
SELECT 
    activity_date AS day,
    COUNT(DISTINCT user_id) AS active_users
FROM Activity
WHERE activity_date BETWEEN DATE '2019-07-27' - INTERVAL '29 days' AND DATE '2019-07-27'
GROUP BY activity_date

-- ==================================================================

