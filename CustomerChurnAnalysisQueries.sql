/**********
Data Cleaning / Validating
**********/


-- 1. Total number of customers
SELECT COUNT(*) AS TotalCustomers
FROM customers;
-- Answer = There are 5,630 customers in this dataset

-- 2. Checking for duplicate rows
SELECT CustomerID, COUNT (CustomerID) AS Count
FROM customers
GROUP BY CustomerID
HAVING COUNT (CustomerID) > 1;
-- Answer = There are no duplicate rows

-- 3. Checking for null values
SELECT 'Tenure' as ColumnName, COUNT(*) AS NullCount 
FROM customers WHERE Tenure IS NULL 
UNION
SELECT 'WarehouseToHome' as ColumnName, COUNT(*) AS NullCount 
FROM customers WHERE WarehouseToHome IS NULL 
UNION
SELECT 'HourSpendOnApp' as ColumnName, COUNT(*) AS NullCount 
FROM customers WHERE HourSpendOnApp IS NULL
UNION
SELECT 'OrderAmountHikeFromLastYear' as ColumnName, COUNT(*) AS NullCount 
FROM customers WHERE OrderAmountHikeFromLastYear IS NULL 
UNION
SELECT 'CouponUsed' as ColumnName, COUNT(*) AS NullCount 
FROM customers WHERE CouponUsed IS NULL 
UNION
SELECT 'OrderCount' as ColumnName, COUNT(*) AS NullCount 
FROM customers WHERE OrderCount IS NULL 
UNION
SELECT 'DaySinceLastOrder' as ColumnName, COUNT(*) AS NullCount 
FROM customers WHERE DaySinceLastOrder IS NULL;

-- 4. Filling null values with the mean from their attribute column
UPDATE customers
SET HourSpendOnApp = (SELECT AVG(HourSpendOnApp) FROM customers)
WHERE HourSpendOnApp IS NULL;

UPDATE customers
SET Tenure = (SELECT AVG(Tenure) FROM customers)
WHERE Tenure IS NULL;

UPDATE customers
SET OrderAmountHikeFromLastYear = (SELECT AVG(OrderAmountHikeFromLastYear) FROM customers)
WHERE OrderAmountHikeFromLastYear IS NULL; 

UPDATE customers
SET WarehouseToHome = (SELECT  AVG(WarehouseToHome) FROM customers)
WHERE WarehouseToHome IS NULL; 

UPDATE customers
SET CouponUsed = (SELECT AVG(CouponUsed) FROM customers)
WHERE CouponUsed IS NULL;

UPDATE customers
SET OrderCount = (SELECT AVG(OrderCount) FROM customers)
WHERE OrderCount IS NULL; 

UPDATE customers
SET DaySinceLastOrder = (SELECT AVG(DaySinceLastOrder) FROM customers)
WHERE DaySinceLastOrder IS NULL; 

-- 5. Creating CustomerStatus attribute based off values of Churn attribute
ALTER TABLE customers
ADD CustomerStatus TEXT;

UPDATE customers
SET CustomerStatus = 
CASE 
    WHEN Churn = 1 THEN 'Churned' 
    WHEN Churn = 0 THEN 'Stayed'
END;

-- 6. Creating ComplainReceived attribute based off values of Complain attribute
ALTER TABLE customers
ADD ComplainReceived TEXT;

UPDATE customers
SET ComplainReceived =  
CASE 
    WHEN Complain = 1 THEN 'Yes'
    WHEN Complain = 0 THEN 'No'
END;

-- 7. Fix redundancy by setting Mobile Phone to Mobile
UPDATE customers
SET PreferredLoginDevice = 'Mobile', PreferredOrderCat = 'Mobile'
WHERE PreferredLoginDevice = 'Mobile Phone'
OR PreferredOrderCat = 'Mobile Phone';

-- 8. Fix redundancy by setting COD to Cash on Delivery
UPDATE customers
SET PreferredPaymentMode = 'Cash on Delivery'
WHERE PreferredPaymentMode = 'COD';

-- 9. Fixing incorrect values in WarehouseToHome
UPDATE customers
SET WarehouseToHome = '27'
WHERE WarehouseToHome = '127';

UPDATE customers
SET WarehouseToHome = '26'
WHERE WarehouseToHome = '126';


/**********
Data Exploration and answering business questions
*********/


-- 1. What is the churn rate? How many customers churned and how many stayed?
SELECT TotalCustomers,
      ChurnedCustomers,
      CAST((ChurnedCustomers * 1.0 / TotalCustomers) * 100 AS DECIMAL(10,2)) AS ChurnRate
FROM
(SELECT COUNT(*) AS TotalCustomers FROM customers) AS Total,
(SELECT COUNT(*) AS ChurnedCustomers FROM customers
WHERE CustomerStatus = 'Churned') AS Churned;
-- Answer = The churn rate is 16.84%

-- 2. What is a churned customer’s typical tenure?
ALTER TABLE customers
ADD TenureRange TEXT;

UPDATE customers
SET TenureRange =
CASE
WHEN ROUND(Tenure, 0) <= 6 THEN '0-6 Months'
WHEN ROUND(Tenure, 0) > 6 AND ROUND(Tenure, 0) <= 12 THEN '6-12 Months'
WHEN ROUND(Tenure, 0) > 12 AND ROUND(Tenure, 0) <= 24 THEN '1-2 Years'
WHEN ROUND(Tenure, 0) > 24 THEN '2+ Years'
END;

SELECT TenureRange,
      COUNT(*) AS TotalCustomers,
      SUM(Churn) AS ChurnedCustomers,
      CAST(SUM(Churn) * 1.0 /COUNT(*) * 100 AS DECIMAL(10,2)) AS ChurnRate
FROM customers
GROUP BY TenureRange
ORDER BY ChurnRate DESC;
-- Answer = 697 of the total 948 churned customers churned within 0-6 months

-- 3. What does churn rate look like depending on preferred login device?
SELECT PreferredLoginDevice,
       COUNT(*) AS TotalCustomers,
       SUM(churn) AS ChurnedCustomers,
       CAST(SUM (churn) * 1.0 / COUNT(*) * 100 AS DECIMAL(10,2)) AS ChurnRate
FROM customers
GROUP BY PreferredLoginDevice;
-- Answer = Churn rate is highest at 19.8% for customers logging in with computers. The churn rate for mobile is 15.62%

-- 4. What does churn rate look like depending on city tier?
SELECT CityTier,
      COUNT(*) AS TotalCustomers,
      SUM(Churn) AS ChurnedCustomers,
      CAST(SUM (churn) * 1.0 / COUNT(*) * 100 AS DECIMAL(10,2)) AS ChurnRate
FROM customers
GROUP BY CityTier
ORDER BY ChurnRate DESC;
-- Answer = City tier 3 has the highest churn rate at 21.4%, city tier 2 follows with 19.8%, and city tier 1 ends with 14.5%


-- 5. What does churn rate look like depending on a customer’s distance from nearest warehouse?
ALTER TABLE customers
ADD WarehouseDistanceRange TEXT;

UPDATE customers
SET WarehouseDistanceRange =
CASE
   WHEN WarehouseToHome <= 10 THEN '0-10 km'
   WHEN WarehouseToHome > 10 AND WarehouseToHome <= 20 THEN '10-20 km'
   WHEN WarehouseToHome > 20 AND WarehouseToHome <= 30 THEN '20-30 km'
   WHEN WarehouseToHome > 30 THEN '30+ km'
END;

SELECT WarehouseDistanceRange,
      COUNT(*) AS TotalCustomers,
      SUM(Churn) AS ChurnedCustomers,
      CAST(SUM(Churn) * 1.0 /COUNT(*) * 100 AS DECIMAL(10,2)) AS ChurnRate
FROM customers
GROUP BY WarehouseDistanceRange
ORDER BY ChurnRate DESC;
-- Answer = The churn rate increases as the distance from warehouses increase

-- 6. What does churn rate look like depending on preferred payment method?
SELECT PreferredPaymentMode,
      COUNT(*) AS TotalCustomers,
      SUM(Churn) AS ChurnedCustomers,
      CAST(SUM(Churn) * 1.0 /COUNT(*) * 100 AS DECIMAL(10,2)) AS ChurnRate
FROM customers
GROUP BY PreferredPaymentMode
ORDER BY ChurnRate DESC;
-- Answer = Customers who use cash on delivery have the highest churn rate at 24.9%

-- 7. Are men or women churning more?
SELECT Gender,
      COUNT(*) AS TotalCustomers,
      SUM(Churn) AS ChurnedCustomers,
      CAST(SUM(Churn) * 1.0 /COUNT(*) * 100 AS DECIMAL(10,2)) AS ChurnRate
FROM customers
GROUP BY Gender
ORDER BY ChurnRate DESC;
-- Answer = Men churn more at 17.7% while women churn at 15.5%

-- 8. Do churned customers spend less time on the app?
SELECT CustomerStatus,
ROUND(AVG(HourSpendOnApp), 2) AS AvgHoursOnApp
FROM customers
GROUP BY CustomerStatus;
-- Answer = Churning and staying customers both roughly average 3 hours weekly on the app

-- 9. What does churn rate look like depending on number of registered devices?
SELECT NumberofDeviceRegistered,
      COUNT(*) AS TotalCustomers,
      SUM(Churn) AS ChurnedCustomers,
      CAST(SUM(Churn) * 1.0 /COUNT(*) * 100 AS DECIMAL(10,2)) AS ChurnRate
FROM customers
GROUP BY NumberofDeviceRegistered
ORDER BY ChurnRate DESC;
-- Answer = As the number of devices registered increases so does the churn rate. The largest number of devices registered is 6 and the churn rate for those customers is 34.6%

-- 10. What does churn rate look like depending on preferred order category?
SELECT PreferredOrderCat,
      COUNT(*) AS TotalCustomers,
      SUM(Churn) AS ChurnedCustomers,
      CAST(SUM(Churn) * 1.0 /COUNT(*) * 100 AS DECIMAL(10,2)) AS ChurnRate
FROM customers
GROUP BY PreferredOrderCat
ORDER BY ChurnRate DESC;
-- Answer = The Mobile category has the highest churn rate at 27.4%. Grocery has the lowest churn rate at 4.88%

-- 11. What are the churn rates for each satisfaction level?
SELECT SatisfactionScore,
      COUNT(*) AS TotalCustomers,
      SUM(Churn) AS ChurnedCustomers,
      CAST(SUM(Churn) * 1.0 /COUNT(*) * 100 AS DECIMAL(10,2)) AS ChurnRate
FROM customers
GROUP BY SatisfactionScore
ORDER BY ChurnRate DESC;
-- Answer = Satisfaction score of 5 has a churn rate of 23.8%, satisfaction of 4 churns at 17.2%, satisfaction of 3 churns at 17.13%, satisfaction of 2 churns at 12.63%, and satisfaction of 1 churns at 11.5%

-- 12. What does churn rate look like depending on marital status?
SELECT MaritalStatus,
      COUNT(*) AS TotalCustomers,
      SUM(Churn) AS ChurnedCustomers,
      CAST(SUM(Churn) * 1.0 /COUNT(*) * 100 AS DECIMAL(10,2)) AS ChurnRate
FROM customers
GROUP BY MaritalStatus
ORDER BY ChurnRate DESC;
-- Answer = Single customers churn at 26.7%, divorced customers churn at 14.6%, and married customers churn at 11.5%

-- 13. Does average number of addresses affect churn rate?
SELECT 
    CustomerStatus,
    ROUND(AVG(NumberOfAddress), 2) AS AvgAddressCount
FROM customers
GROUP BY CustomerStatus
ORDER BY CustomerStatus;
-- Answer = On average, both churning and staying customers have 4 addresses

-- 14. What does churn rate look like depending on complaints?
SELECT ComplainReceived,
      COUNT(*) AS TotalCustomers,
      SUM(Churn) AS ChurnedCustomers,
      CAST(SUM(Churn) * 1.0 /COUNT(*) * 100 AS DECIMAL(10,2)) AS ChurnRate
FROM customers
GROUP BY ComplainReceived
ORDER BY ChurnRate DESC;
-- Answer = Customers who complained had a 31.67% churn rate. Customers who didn’t complain had a 10.92% churn rate.

-- 15. What does coupon usage tell us?
SELECT CustomerStatus, SUM(CouponUsed) AS SumOfCouponUsed
FROM customers
GROUP BY CustomerStatus;
-- Answer = Customers who stay use substantially more coupons than customers who churn

-- 16. How does cashback influence churn rate?
ALTER TABLE customers
ADD CashbackAmountRange TEXT;

UPDATE customers
SET CashbackAmountRange =
CASE
   WHEN CashbackAmount <= 100 THEN 'Low Cashback Amount'
   WHEN CashbackAmount > 100 AND CashbackAmount <= 200 THEN 'Moderate Cashback Amount'
   WHEN CashbackAmount > 200 AND CashbackAmount <= 300 THEN 'High Cashback Amount'
   WHEN CashbackAmount > 300 THEN 'Very High Cashback Amount'
END;

SELECT CashbackAmountRange,
      COUNT(*) AS TotalCustomers,
      SUM(Churn) AS ChurnedCustomers,
      CAST(SUM(Churn) * 1.0 /COUNT(*) * 100 AS DECIMAL(10,2)) AS ChurnRate
FROM customers
GROUP BY CashbackAmountRange
ORDER BY ChurnRate DESC;
-- Answer = Customers with a moderate cashback amount had the highest churn rate of 18.9%, followed by high cashback amount at 10.7%, then very high cashback amount at 6.4%, and lastly low cashback amount at 0%

-- 17. Average order count?
SELECT 
    CustomerStatus,
    ROUND(AVG(OrderCount), 2) AS AvgOrderCount
FROM customers
GROUP BY CustomerStatus
ORDER BY CustomerStatus;
-- Answer = The average order count for churning and staying customers was about 3

-- 18. What’s the average days since last order for churned and staying customers?
SELECT 
    CustomerStatus,
    ROUND(AVG(DaySinceLastOrder), 2) AS AvgDaySinceLastOrder
FROM customers
GROUP BY CustomerStatus
ORDER BY CustomerStatus;
-- Answer = The average days since last order for churned customers was about 3.3. For staying customers it was about 4.8

-- 19. How many people churned with just 1 purchase?
SELECT 
    OrderCount,
    COUNT(*) AS TotalCustomers,
    SUM(Churn) AS ChurnedCustomers,
    CAST(SUM(Churn) * 1.0 / COUNT(*) * 100 AS DECIMAL(10,2)) AS ChurnRate
FROM customers
WHERE OrderCount = 1
GROUP BY OrderCount;
-- Answer = 1751 customers made 1 purchase, and of those customers 316 churned. This gives us the churn rate of 18%


/**********
Extra Data Exploration Queries
**********/


-- 20. How many customers complained / didn’t and left / stayed
SELECT 
    ComplainReceived,
    CustomerStatus,
    COUNT(*) AS TotalCustomers,
    SUM(Churn) AS ChurnedCustomers,
    CAST(SUM(Churn) * 1.0 / COUNT(*) * 100 AS DECIMAL(10,2)) AS ChurnRate
FROM customers
GROUP BY ComplainReceived, CustomerStatus
ORDER BY ComplainReceived, CustomerStatus;

-- 21. Satisfaction levels for each customer churned or staying
SELECT 
    SatisfactionScore,
    CustomerStatus,
    COUNT(*) AS TotalCustomers,
    SUM(Churn) AS ChurnedCustomers
FROM customers
GROUP BY SatisfactionScore, CustomerStatus
ORDER BY SatisfactionScore, CustomerStatus;

-- 22. City tiers and satisfaction levels and complaints and churn
SELECT 
    CityTier,
    SatisfactionScore,
    ComplainReceived,
    COUNT(*) AS TotalCustomers,
    SUM(Churn) AS ChurnedCustomers,
    CAST(SUM(Churn) * 1.0 / COUNT(*) * 100 AS DECIMAL(10,2)) AS ChurnRate
FROM customers
GROUP BY CityTier, SatisfactionScore, ComplainReceived
ORDER BY CityTier, SatisfactionScore, ComplainReceived;