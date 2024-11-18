ALTER TABLE [dbo].[CovidDeaths]
ALTER COLUMN total_cases DECIMAL(18,2);

ALTER TABLE [dbo].[CovidDeaths]
ALTER COLUMN total_deaths DECIMAL(18,2);

ALTER TABLE [dbo].[CovidDeaths]
ALTER COLUMN new_cases DECIMAL(18,2);

ALTER TABLE [dbo].[CovidDeaths]
ALTER COLUMN new_deaths DECIMAL(18,2);

ALTER TABLE [dbo].[CovidVaccinations]
ALTER COLUMN new_vaccinations DECIMAL(18,2);


SELECT location, date, total_cases, total_deaths, population
FROM [dbo].[CovidDeaths]
ORDER BY 1,2

-- By countries

-- What percentage of population Got COVID
SELECT location, population, MAX(total_cases) AS highestInfectCount, MAX(total_cases/population)*100 AS infectPerc
FROM [dbo].[CovidDeaths]
GROUP BY location, population
ORDER BY 1,2;

-- Total Cases vs Total Death
SELECT 
    location,
    population,
    (MAX(total_deaths) / NULLIF(MAX(total_cases), 0) * 100) AS Percentage
FROM [dbo].[CovidDeaths]
GROUP BY location, population
ORDER BY 3 DESC;


-- Countries with Highest Death Count per Population
SELECT location, MAX(total_deaths) AS TotDeathCount
FROM [dbo].[CovidDeaths]
WHERE continent is not null
GROUP BY location
ORDER BY 2 DESC


-- By continent

-- Countries with Highest Death Count per Population
SELECT continent, MAX(total_deaths) AS TotDeathCount
FROM [dbo].[CovidDeaths]
WHERE continent is not null
GROUP BY continent
ORDER BY 2 DESC


-- Global Numbers
SELECT 
    date,
    SUM(new_cases) AS totNewCases,
	SUM(new_deaths) AS totNewDeath,
    SUM(new_deaths) / NULLIF(SUM(new_cases),0) * 100 AS DeathPercentage
FROM [dbo].[CovidDeaths]
WHERE continent is not null
GROUP BY date
ORDER BY 1,2;

--Total Population vs Vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as rollPeopleVaccinated
FROM [dbo].[CovidDeaths] dea
JOIN [dbo].[CovidVaccinations] vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3 

--Use CTE
WITH PopVsVac (continent, location, date, population, new_vaccinations, rollPeopleVaccinated)
AS(
SELECT dea.continent, dea.location, dea.date, MAX(dea.population) OVER (Partition by dea.location) AS population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as rollPeopleVaccinated
FROM [dbo].[CovidDeaths] dea
JOIN [dbo].[CovidVaccinations] vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3
)
SELECT *, (rollPeopleVaccinated/population)*100
FROM PopVsVac
ORDER BY 7 DESC

--Use TEMP
DROP TABLE IF EXISTS #PercPopulatVaccinated
Create table #PercPopulatVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rollPeopleVaccinated numeric
)

INSERT INTO #PercPopulatVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as rollPeopleVaccinated
FROM [dbo].[CovidDeaths] dea
JOIN [dbo].[CovidVaccinations] vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3

SELECT *, (rollPeopleVaccinated/population)*100 AS PercPopulatVaccinated
FROM #PercPopulatVaccinated

--Creating view for later visualization
CREATE VIEW PercPopulationVaccinated AS 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as rollPeopleVaccinated
FROM [dbo].[CovidDeaths] dea
JOIN [dbo].[CovidVaccinations] vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent is not null 

SELECT *, (rollPeopleVaccinated/population)*100 AS PercPopulatVaccinated
FROM PercPopulationVaccinated
ORDER BY PercPopulatVaccinated DESC



