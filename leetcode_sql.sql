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

-- LeetCode 1070 - Product Sales Analysis III
-- Pattern: CTE + Window Function (DENSE_RANK)
-- Idea: Rank sales years for each product and return all rows where the year is the earliest (rank = 1).
-- My Solution

WITH cte AS (
    SELECT
        product_id,
        year AS first_year,
        DENSE_RANK() OVER(PARTITION BY product_id ORDER BY year) AS first_app,
        quantity,
        price
    FROM Sales
)
SELECT
    product_id,
    first_year,
    quantity,
    price
FROM cte
WHERE first_app = 1;

-- Best Solution
-- Changes:
-- 1. Used MIN(year) + JOIN which is simpler and commonly used for this pattern.
-- 2. Avoids window function when only the first year per product is required.

SELECT
    s.product_id,
    s.year AS first_year,
    s.quantity,
    s.price
FROM Sales s
JOIN (
    SELECT
        product_id,
        MIN(year) AS first_year
    FROM Sales
    GROUP BY product_id
) first_sales
    ON s.product_id = first_sales.product_id
   AND s.year = first_sales.first_year;

-- ================================================================

-- LeetCode 1731 - The Number of Employees Which Report to Each Employee
-- Pattern: Self Join + GROUP BY + Aggregation
-- Idea: Join each manager with their direct reports, then count reports and calculate the rounded average age of those reports.
-- My Solution

SELECT
    e1.employee_id,
    e1.name,
    COUNT(*) AS reports_count,
    ROUND(AVG(e2.age), 0) AS average_age
FROM Employees e1
JOIN Employees e2
    ON e1.employee_id = e2.reports_to
GROUP BY
    e1.employee_id,
    e1.name
ORDER BY e1.employee_id;

-- ================================================================

-- LeetCode 180 - Consecutive Numbers
-- Pattern: Window Function (LEAD) / Consecutive Rows
-- Idea: Use LEAD() to compare the current number with the next two rows. 
-- If all three values are equal, the number appears at least three times consecutively.

-- My Solution
SELECT DISTINCT
    t.num AS ConsecutiveNums
FROM (
    SELECT 
        *,
        LEAD(num,1) OVER (ORDER BY id) AS next1,
        LEAD(num,2) OVER (ORDER BY id) AS next2
    FROM Logs
) t
WHERE num = next1 
  AND num = next2;

-- =========================================================

-- LeetCode 1204 - Last Person to Fit in the Bus
-- Pattern: Window Function (Running Total / Cumulative Sum)
-- Idea: Compute cumulative weight in boarding order using SUM() OVER (ORDER BY turn). 
-- Keep rows where total weight ≤ 1000 and return the last person in the queue.

-- My Solution
SELECT 
    t.person_name
FROM (
    SELECT 
        person_name,
        turn,
        SUM(weight) OVER (ORDER BY turn) AS tot_sum
    FROM Queue
) t
WHERE tot_sum <= 1000
ORDER BY turn DESC
LIMIT 1;

-- =========================================================

-- LeetCode 626 - Exchange Seats
-- Pattern: CASE WHEN + Odd/Even Row Transformation
-- Idea: Swap seat ids by checking parity. Odd ids move to id+1, even ids move to id-1. 
-- If the last id is odd (no pair), keep it unchanged.

-- My Solution
SELECT 
    CASE
        WHEN id % 2 = 1 AND (SELECT MAX(id) FROM Seat) = id THEN id
        WHEN id % 2 = 1 THEN id + 1
        ELSE id - 1
    END AS id,
    student
FROM Seat
ORDER BY id;

-- =========================================================

-- LeetCode 1341 - Movie Rating
-- Pattern: Aggregation + ORDER BY + UNION ALL
-- Idea: First, count how many ratings each user gave and pick the top one by count and lexicographical order. 
-- Then, compute the highest average movie rating in February 2020 and pick the lexicographically smaller title in case of a tie.

-- My Solution
(SELECT 
    u.name AS results  
FROM Users u
JOIN MovieRating mr 
    ON u.user_id = mr.user_id
GROUP BY u.name
ORDER BY COUNT(*) DESC, u.name
LIMIT 1)

UNION ALL

(SELECT 
    m.title AS results
FROM Movies m
JOIN MovieRating mr 
    ON m.movie_id = mr.movie_id
WHERE mr.created_at >= '2020-02-01'
  AND mr.created_at < '2020-03-01'
GROUP BY m.movie_id, m.title
ORDER BY AVG(mr.rating) DESC, m.title
LIMIT 1);

-- =========================================================

-- LeetCode 602 - Friend Requests II: Who Has the Most Friends
-- Pattern: UNION ALL + GROUP BY
-- Idea: Combine requester_id and accepter_id into one list of people, count how many times each person appears, then return the one with the highest count.
-- My Solution

WITH cte AS (
    SELECT requester_id AS id
    FROM RequestAccepted

    UNION ALL

    SELECT accepter_id AS id
    FROM RequestAccepted
)
SELECT
    id,
    COUNT(*) AS num
FROM cte
GROUP BY id
ORDER BY num DESC
LIMIT 1;

-- =========================================================

-- LeetCode 585 - Investments in 2016
-- Pattern: GROUP BY + Subquery Filtering
-- Idea: Keep records where tiv_2015 appears more than once, and where the (lat, lon) location pair is unique. Then sum tiv_2016 and round to 2 decimals.
-- My Solution

SELECT
    ROUND(SUM(tiv_2016)::numeric, 2) AS tiv_2016
FROM Insurance
WHERE tiv_2015 IN (
    SELECT tiv_2015
    FROM Insurance
    GROUP BY tiv_2015
    HAVING COUNT(*) > 1
)
AND (lat, lon) IN (
    SELECT lat, lon
    FROM Insurance
    GROUP BY lat, lon
    HAVING COUNT(*) = 1
);

-- =========================================================
-- LeetCode 185 - Department Top Three Salaries
-- Pattern: JOIN + Window Function (DENSE_RANK)
-- Idea: Join employees with departments, rank unique salaries within each department in descending order, then keep employees whose salary rank is within the top 3.
-- My Solution

WITH cte AS (
    SELECT
        d.name AS Department,
        e.name AS Employee,
        e.salary AS Salary,
        DENSE_RANK() OVER (
            PARTITION BY d.id
            ORDER BY e.salary DESC
        ) AS dr
    FROM Department d
    JOIN Employee e
        ON e.departmentId = d.id
)
SELECT
    Department,
    Employee,
    Salary
FROM cte
WHERE dr <= 3;
