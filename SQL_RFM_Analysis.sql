SELECT * FROM sales_2025

--Analysis

--Check which product give us the more revenue
SELECT ProductType,SUM(OrderValue) as Revenue
FROM sales_2025
GROUP BY ProductType
ORDER BY Revenue DESC

--Check which month give us the most revenue
SELECT MonthName,SUM(OrderValue) as Revenue
FROM sales_2025
GROUP BY MonthName
ORDER BY Revenue DESC

--Check which customer buy more orders and who give us the highest sales
SELECT CustomerID,SUM(OrderValue) as Revenue,COUNT(OrderID) as Total_Orders
FROM sales_2025
GROUP BY CustomerID
ORDER BY Revenue DESC

--RFM Analysis

SELECT CustomerID,
	SUM(OrderValue) as Monetary_Value,
	COUNT(OrderID) as Frequency,
	MAX(OrderDate) as last_order_date,
	(select MAX(OrderDate) FROM sales_2025) as Max_OrderDate,
	DATEDIFF(DD,Max(OrderDate),(select MAX(OrderDate) FROM sales_2025)) as Recency
	FROM sales_2025
	GROUP BY CustomerID

--R_F_M Scores (CTE)
WITH rfm as 
(
SELECT CustomerID,
	SUM(OrderValue) as Monetary_Value,
	COUNT(OrderID) as Frequency,
	MAX(OrderDate) as last_order_date,
	(select MAX(OrderDate) FROM sales_2025) as Max_OrderDate,
	DATEDIFF(DD,Max(OrderDate),(select MAX(OrderDate) FROM sales_2025)) as Recency
	FROM sales_2025
	GROUP BY CustomerID) 
SELECT *,
	NTILE(4) OVER(ORDER BY Recency DESC) as r_score,
	NTILE(4) OVER(ORDER BY Frequency ASC) as f_score,
	NTILE(4) OVER(ORDER BY Monetary_Value ASC) as m_score
FROM rfm

--calculate rfm score
--First CTE (Calculate r_f_m score)
WITH rfm as
(
SELECT CustomerID,
	SUM(OrderValue) as Monetary_Value,
	COUNT(OrderID) as Frequency,
	MAX(OrderDate) as last_order_date,
	(select MAX(OrderDate) FROM sales_2025) as Max_OrderDate,
	DATEDIFF(DD,Max(OrderDate),(select MAX(OrderDate) FROM sales_2025)) as Recency
	FROM sales_2025
	GROUP BY CustomerID),
rfm_cal as                        --(2nd CTE Calculate rfm score)
(
SELECT *,
	NTILE(4) OVER(ORDER BY Recency DESC) as r_score,
	NTILE(4) OVER(ORDER BY Frequency ASC) as f_score,
	NTILE(4) OVER(ORDER BY Monetary_Value ASC) as m_score
FROM rfm )

SELECT *,
	r_score,f_score,m_score as rfm_cell,
	cast(r_score as varchar)+cast(f_score as varchar)+cast(m_score as varchar) as rfm_score
FROM rfm_cal

--Now to see all the results we have to run this long query again and again so to converrt it into a single table and query
--3rd CTE AND FINAL CTE (That create the table of it)
DROP TABLE IF EXISTS #rfm;
WITH rfm as
(
SELECT CustomerID,
	SUM(OrderValue) as Monetary_Value,
	COUNT(OrderID) as Frequency,
	MAX(OrderDate) as last_order_date,
	(select MAX(OrderDate) FROM sales_2025) as Max_OrderDate,
	DATEDIFF(DD,Max(OrderDate),(select MAX(OrderDate) FROM sales_2025)) as Recency
	FROM sales_2025
	GROUP BY CustomerID),
rfm_cal as
(
SELECT *,
	NTILE(4) OVER(ORDER BY Recency DESC) as r_score,
	NTILE(4) OVER(ORDER BY Frequency ASC) as f_score,
	NTILE(4) OVER(ORDER BY Monetary_Value ASC) as m_score
FROM rfm )

SELECT *,
	cast(r_score as varchar)+cast(f_score as varchar)+cast(m_score as varchar) as rfm_score
into #rfm
FROM rfm_cal

--Now we just use this simple query to check the rfm score 
select * from #rfm

--Select only r_f_m, rfm score
SELECT CustomerID,r_score,f_score,m_score,rfm_score from #rfm

--Divide the customers into segments
SELECT CustomerID,r_score,f_score,m_score,rfm_score,
	CASE
		WHEN rfm_score in (111,112,121,122,123,132,211,212,114,141) then 'lost customers' --lost customers
		WHEN rfm_score in (133,134,143,244,334,343,144) then 'slipping away,cannot lose'  --(Big spenders who haven't purchased lately),sliiping away
		WHEN rfm_score in (311,411,331) then 'new customers'
		WHEN rfm_score in (222,223,233,322) then 'potential churners'
		WHEN rfm_score in (323,333,321,422,332,432) then 'active'  --(Customers who buy often & recently,but at low price)
		WHEN rfm_score in (433,434,443,444,344) then 'loyal'
	END rfm_segment
from #rfm

--RFM Analysis end heres

--Now we create a permanent table to connect it into powerbi and make visuals from it

-- Drop the table if it already exists
DROP TABLE IF EXISTS rfm_final;
-- Create the permanent table with exactly the columns you need
SELECT 
    CustomerID,
    r_score,
    f_score,
    m_score,
    rfm_score,
     CASE
        WHEN rfm_score in (111,112,121,122,123,132,211,212,114,141) THEN 'lost customers'
        WHEN rfm_score in (133,134,143,244,334,343,144) THEN 'slipping away, cannot lose'
        WHEN rfm_score in (311,411,331) THEN 'new customers'
        WHEN rfm_score in (222,223,233,322) THEN 'potential churners'
        WHEN rfm_score in (323,333,321,422,332,432) THEN 'active'
        WHEN rfm_score in (433,434,443,444,344) THEN 'loyal'
    END AS rfm_segment
INTO rfm_final
FROM #rfm;

select * from rfm_final

--Check SQL ServerName
SELECT @@SERVERNAME AS ServerName;