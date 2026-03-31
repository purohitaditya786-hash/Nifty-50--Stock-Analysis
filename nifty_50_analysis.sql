-- PROJECT: NIFTY 50 MEGA DATA ANALYSIS
-- DATABASE: stock_db | TABLE: nifty_50
-- Author: [Saransh Purohit]

USE stock_db;

-- 1. SORTING & FILTERING (Top 10 High Volatility Days)
SELECT YEAR,month,Day, high_price, low_price, close_price, 
       ROUND(((high_price - low_price) / low_price) * 100, 2) AS Volatility_Percentage
FROM nifty_50
WHERE volume > 1000000 
ORDER BY Volatility_Percentage DESC
LIMIT 10;

-- 2. 7-DAY MOVING AVERAGE (Short-term Trend)
SELECT YEAR,month,Day, close_price,
       ROUND(AVG(close_price) OVER (ORDER BY YEAR,month,Day ROWS BETWEEN 6 PRECEDING AND CURRENT ROW), 2) AS Moving_Avg_7Day
FROM nifty_50;

-- 3. DAILY RETURN IN % (Day-on-Day Change)
SELECT  YEAR,month,Day,close_price, 
       LAG(close_price) OVER (ORDER BY YEAR,month,Day) as Previous_Close,
       ROUND(((close_price - LAG(close_price) OVER (ORDER BY YEAR,month,Day)) / LAG(close_price) OVER (ORDER BY YEAR,month,Day)) * 100, 2) AS Daily_Return_Pct
FROM nifty_50;

-- 4. AVG PRICE RANGE & VOLATILITY (Yearly)
SELECT YEAR,
       ROUND(AVG(high_price - low_price), 2) AS Avg_Daily_Range,
       ROUND(AVG(((high_price - low_price) / low_price) * 100), 2) AS Avg_Volatility
FROM nifty_50
GROUP BY YEAR;

-- 5. MARKET STRENGTH (High Volume Bullish Days)
SELECT  YEAR,month,Day,close_price, volume
FROM nifty_50
WHERE close_price > (SELECT LAG(close_price) OVER (ORDER BY YEAR,month,Day)) 
      AND volume > (SELECT AVG(volume) FROM nifty_50)
ORDER BY YEAR,month,Day DESC;

-- 6. PRICE MOMENTUM (30-Day Performance)
SELECT YEAR, month, Day, close_price,
       ROUND(((close_price - LAG(close_price, 30) OVER (ORDER BY YEAR,month,Day)) / LAG(close_price, 30) OVER (ORDER BY YEAR,month,Day)) * 100, 2) AS Momentum_30D
FROM nifty_50;

-- 7. TURNOVER EFFICIENCY (Liquidity Analysis)
SELECT YEAR, month, Day, turnover, 
       ABS(ROUND(((close_price - LAG(close_price) OVER (ORDER BY YEAR,month,Day )) / LAG(close_price) OVER (ORDER BY YEAR,month,Day)) * 100, 2)) as Price_Move_Abs,
       ROUND(turnover / NULLIF(ABS(((close_price - LAG(close_price) OVER (ORDER BY YEAR,month,Day)) / LAG(close_price) OVER (ORDER BY YEAR,month,Day)) * 100), 0), 2) AS Turnover_Efficiency
FROM nifty_50;

-- 8. BULLISH VS BEARISH TREND (Market Sentiment)
WITH TrendData AS (
    SELECT YEAR, month, Day, close_price,
           AVG(close_price) OVER (ORDER BY YEAR,month,Day ROWS BETWEEN 49 PRECEDING AND CURRENT ROW) AS MA_50
    FROM nifty_50
)
SELECT YEAR, month, Day, close_price, ROUND(MA_50, 2) as Moving_Avg_50,
       CASE 
            WHEN close_price > MA_50 THEN 'BULLISH'
            WHEN close_price < MA_50 THEN 'BEARISH'
            ELSE 'NEUTRAL'
       END AS Market_Sentiment
FROM TrendData;

-- 9. RANKING (Top 3 Turnover Days per Year)
SELECT YEAR,month,Day, turnover, Turnover_Rank
FROM (
    SELECT YEAR,month,Day, turnover,
           DENSE_RANK() OVER (PARTITION BY YEAR ORDER BY turnover DESC) as Turnover_Rank
    FROM nifty_50
) AS RankedData
WHERE Turnover_Rank <= 3;

-- 10. RSI BASE LOGIC (Gains vs Losses)
SELECT YEAR,month,Day, 
       CASE WHEN close_price > LAG(close_price) OVER (ORDER BY  YEAR,month,Day) THEN ROUND(close_price - LAG(close_price) OVER (ORDER BY YEAR,month,Day), 2) ELSE 0 END AS Gain,
       CASE WHEN close_price < LAG(close_price) OVER (ORDER BY  YEAR,month,Day ) THEN ROUND(LAG(close_price) OVER (ORDER BY YEAR,month,Day) - close_price, 2) ELSE 0 END AS Loss
FROM nifty_50;