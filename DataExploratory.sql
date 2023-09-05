select * from [dbo].[EnergyData]
select * from [dbo].[EnvironmentData]

-- View the first 5 rows of EnergyData table
SELECT TOP 5 * FROM BIEnergy.dbo.EnergyData;

-- View the first 5 rows of EnvironmentData table
SELECT TOP 5 * FROM BIEnergy.dbo.EnvironmentData;

--Calculate the total electricity generation for each year:
SELECT energy_year, SUM(Total_Electricity_Generation_Net) AS Total_Electricity_Generation
FROM BIEnergy.dbo.EnergyData
GROUP BY energy_year
ORDER BY energy_year;

--Find the years with the highest and lowest CO2 emissions per capita:
SELECT TOP 1 env_year, CO2_Emissions_CMT
FROM BIEnergy.dbo.EnvironmentData
ORDER BY CO2_Emissions_CMT DESC;

SELECT TOP 1 env_year, CO2_Emissions_CMT
FROM BIEnergy.dbo.EnvironmentData
ORDER BY CO2_Emissions_CMT ASC;

--Find the top 5 years with the highest total energy consumption:
SELECT TOP 5 energy_year, Total_Energy_Consumption_Mt
FROM BIEnergy.dbo.EnergyData
ORDER BY Total_Energy_Consumption_Mt DESC;


--Calculate the average CO2 emissions per square kilometer for each year:

SELECT env_year, CO2_Emissions_Total_mt, Area_SqKm AS Avg_CO2_Emissions_Per_SqKm
FROM BIEnergy.dbo.EnvironmentData;

--Retrieve the years with the lowest net hydroelectric power generation:
SELECT energy_year, Hydro_Power_Generation_Net
FROM BIEnergy.dbo.EnergyData
ORDER BY Hydro_Power_Generation_Net ASC;

--Average CO2 Emissions by Energy Source:
--This query calculates the average CO2 emissions per year
--and groups them by the percentage of alternative and nuclear energy used.
--It helps identify if there's any correlation between the use of alternative energy sources and CO2 emissions.

SELECT
    energy_year,
    AVG(CO2_Emissions_Total_mt) AS Avg_CO2_Emissions,
    Alternative_Nuclear_Energy_Percentage
FROM [dbo].[EnvironmentData]
JOIN [dbo].[EnergyData]
    ON EnvironmentData.env_year = EnergyData.energy_year
GROUP BY energy_year, Alternative_Nuclear_Energy_Percentage
ORDER BY energy_year;

--Top 5 Years with the Highest Total Energy Consumption:
SELECT TOP 5
    energy_year,
    Total_Energy_Consumption_Mt
FROM [dbo].[EnergyData]
ORDER BY Total_Energy_Consumption_Mt DESC;

--CO2 Emissions per Capita Ranking:
SELECT
    env_year,
    CO2_Emissions_CMT,
    RANK() OVER (ORDER BY CO2_Emissions_CMT) AS CO2_Emissions_Rank
FROM [dbo].[EnvironmentData]

--This query calculates the growth rate of electricity consumption between consecutive years,
--helping you understand the trend and fluctuations in energy usage.
SELECT
    energy_year,
    Total_Electricity_Consumption_Net,
    LAG(Total_Electricity_Consumption_Net) OVER (ORDER BY energy_year) AS Prev_Year_Electricity_Consumption,
    (Total_Electricity_Consumption_Net - LAG(Total_Electricity_Consumption_Net) OVER (ORDER BY energy_year)) / LAG(Total_Electricity_Consumption_Net) OVER (ORDER BY energy_year) * 100 AS Growth_Rate
FROM [dbo].[EnergyData];

--Calculate Yearly Change in CO2 Emissions:
WITH CO2_Emissions_CTE AS (
    SELECT
        env_year,
        CO2_Emissions_Total_mt,
        LAG(CO2_Emissions_Total_mt) OVER (ORDER BY env_year) AS Prev_CO2_Emissions
    FROM [dbo].[EnvironmentData]
)
SELECT
    env_year,
    CO2_Emissions_Total_mt,
    CO2_Emissions_Total_mt - Prev_CO2_Emissions AS Yearly_Change
FROM CO2_Emissions_CTE;

--Identify Years with the Highest Hydroelectric Power Generation:
SELECT
    energy_year,
    Hydro_Power_Generation_Net,
    RANK() OVER (ORDER BY Hydro_Power_Generation_Net DESC) AS Hydro_Power_Rank
from [dbo].[EnergyData];

--Calculate Moving Average of Total Electricity Consumption:
SELECT
    energy_year,
    Total_Electricity_Consumption_Net,
    AVG(Total_Electricity_Consumption_Net) OVER (ORDER BY energy_year ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS Moving_Avg_Consumption
FROM[dbo].[EnergyData];

--Calculate the Percentage Change in Total Energy Consumption by Year:
WITH Energy_Consumption_CTE AS (
    SELECT
        energy_year,
        Total_Electricity_Consumption_Net,
        LAG(Total_Electricity_Consumption_Net) OVER (ORDER BY energy_year) AS Prev_Year_Consumption
    FROM [dbo].[EnergyData]
)
SELECT
    energy_year,
    Total_Electricity_Consumption_Net,
    (Total_Electricity_Consumption_Net - Prev_Year_Consumption) / Prev_Year_Consumption * 100 AS Consumption_Percentage_Change
FROM Energy_Consumption_CTE;

--a Trigger to Update CO2 Emissions Rank in the EnvironmentData Table
CREATE TRIGGER UpdateCO2EmissionsRank
ON [dbo].[EnvironmentData]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    UPDATE E
    SET CO2_Emissions_Rank = R.Rank
    FROM [dbo].[EnvironmentData] E
    INNER JOIN (
        SELECT env_year, RANK() OVER (ORDER BY CO2_Emissions_CMT) AS Rank
        FROM [dbo].[EnvironmentData]
    ) R ON E.env_year = R.env_year;
END;

--Calculate Total Energy Consumption Percentage by Energy Source
WITH Total_Energy_Consumption AS (
    SELECT energy_year,
           Total_Electricity_Consumption_Net,
           SUM(Total_Electricity_Consumption_Net) OVER () AS Total_Consumption
    FROM dbo.[EnergyData]
)
SELECT energy_year,
       Total_Electricity_Consumption_Net,
       (Total_Electricity_Consumption_Net / Total_Consumption) * 100 AS Consumption_Percentage
FROM Total_Energy_Consumption;

--Create a Procedure to Calculate Average Electricity Generation by Energy Source:
CREATE PROCEDURE CalculateAvgElectricityGeneration
AS
BEGIN
    SELECT AVG(Hydro_Power_Generation_Net) AS Avg_Hydro_Generation,
           AVG(Thermal_Electricity_Generation_Net) AS Avg_Thermal_Generation,
           AVG(Total_Net_Electricity_Generation) AS Avg_Total_Generation
    FROM BIEnergy.EnergyData;
END;

--Create a Trigger to Update Total Energy Consumption when New Data is Inserted:
CREATE TRIGGER UpdateTotalEnergyConsumption
ON [dbo].[EnergyData]
AFTER INSERT
AS
BEGIN
    UPDATE E
    SET Total_Electricity_Consumption_Net = E.Hydro_Power_Consumption_Net + E.Total_Net_Electricity_Consumption
    FROM BIEnergy.EnergyData E
    INNER JOIN inserted I ON E.energy_year = I.energy_year;
END;

--Calculate CO2 Emissions Growth Rate:
WITH CO2_Emissions_CTE AS (
    SELECT
        env_year,
        CO2_Emissions_Total_mt,
        LAG(CO2_Emissions_Total_mt) OVER (ORDER BY env_year) AS Prev_CO2_Emissions
    FROM [dbo].[EnvironmentData]
)
SELECT
    env_year,
    CO2_Emissions_Total_mt,
    (CO2_Emissions_Total_mt - Prev_CO2_Emissions) / Prev_CO2_Emissions * 100 AS Emissions_Growth_Rate
FROM CO2_Emissions_CTE;
