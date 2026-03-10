-- LeetCode 577
-- Employee Bonus

-- Problem:
-- Return the name and bonus of employees whose bonus is less than 1000
-- or who did not receive a bonus.

-- Topic:
-- LEFT JOIN
-- NULL filtering

-- Idea:
-- Use LEFT JOIN to keep employees without bonuses.
-- Then filter bonuses < 1000 or NULL.

-- Solution
SELECT 
    e.name,
    b.bonus 
FROM Employee e
LEFT JOIN Bonus b 
    ON e.empId = b.empId
WHERE b.bonus < 1000 
   OR b.bonus IS NULL;
