SELECT * 
FROM Portfolio_Project..CovidDeaths$
WHERE continent is not null
ORDER BY 3,4

-- SELECT * 
--FROM Portfolio_Project..CovidVaccinations$
--order by 3,4

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM Portfolio_Project..CovidDeaths$
WHERE continent is not null
ORDER BY 1,2

-- Total Cases Versus Total Deaths(likelihood of dying from covid) in the United States
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as covid_death_percentage
FROM Portfolio_Project..CovidDeaths$
WHERE location = 'United States' AND continent is not null
ORDER BY 1,2

--Total Cases Versus Population in the United States
SELECT location, date, total_cases, population, (total_cases/population)*100 as infected_population_percentage
FROM Portfolio_Project..CovidDeaths$
WHERE location = 'United States' AND continent is not null
ORDER BY 1,2

--Highest Infection Rate by Population
SELECT location, population, MAX(total_cases) as highest_infection_count, MAX((total_cases/population)*100) as infected_population_percentage
FROM Portfolio_Project..CovidDeaths$
WHERE continent is not null
GROUP BY location, population
ORDER BY infected_population_percentage DESC

--Highest Death Rate by Population
SELECT location, population, MAX(CAST(total_deaths as int)) as highest_death_count, MAX((total_deaths/population)*100) as death_population_percentage
FROM Portfolio_Project..CovidDeaths$
WHERE continent is not null
GROUP BY location, population
ORDER BY death_population_percentage DESC

--By Continent
SELECT continent, MAX(CAST(total_deaths as int)) as highest_death_count
FROM Portfolio_Project..CovidDeaths$
WHERE continent is not null
GROUP BY continent
ORDER BY highest_death_count DESC

-- Global Numbers
SELECT date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as death_percentage
FROM Portfolio_Project..CovidDeaths$
WHERE continent is not null
GROUP BY date
ORDER BY 1,2

SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as death_percentage
FROM Portfolio_Project..CovidDeaths$
WHERE continent is not null
--GROUP BY date
ORDER BY 1,2

--Joining tables
SELECT *
FROM Portfolio_Project..CovidDeaths$ d
JOIN Portfolio_Project..CovidVaccinations$ v
	ON d.location = v.location
	AND d.date = v.date

--Rolling Vaccinations
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, SUM(CAST(v.new_vaccinations as int)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) as rolling_vaccinations_by_location, 
FROM Portfolio_Project..CovidDeaths$ d
JOIN Portfolio_Project..CovidVaccinations$ v
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent is not null
ORDER BY 2,3


-- Total Polopulation vs Vaccinations

--CTE
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, Rolling_Vaccinations_by_Location)
AS
(
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, SUM(CAST(v.new_vaccinations as int)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) as rolling_vaccinations_by_location
FROM Portfolio_Project..CovidDeaths$ d
JOIN Portfolio_Project..CovidVaccinations$ v
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent is not null
--ORDER BY 2,3
)
SELECT *, (Rolling_Vaccinations_by_Location/Population)*100 as Rolling_Vaccination_Percentage
FROM PopvsVac
ORDER BY location, Date

--Temp Table

DROP TABLE if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(Continent nvarchar(255),
location nvarchar(255),
date dateTime,
Population numeric,
New_Vaccinations numeric,
RollingPeopleVaccinated numeric)


Insert INTO #PercentPopulationVaccinated
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, SUM(CAST(v.new_vaccinations as int)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) as rolling_vaccinations_by_location
FROM Portfolio_Project..CovidDeaths$ d
JOIN Portfolio_Project..CovidVaccinations$ v
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent is not null
--ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated/Population)*100 as Rolling_Vaccination_Percentage
FROM #PercentPopulationVaccinated




--View for later visualizations
CREATE VIEW PercentPopulationVaccinated as
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, SUM(CAST(v.new_vaccinations as int)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) as rolling_vaccinations_by_location
FROM Portfolio_Project..CovidDeaths$ d
JOIN Portfolio_Project..CovidVaccinations$ v
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent is not null

-- Extras
CREATE VIEW TotalNewTestsByLocation as 
SELECT location, SUM(CAST(new_tests as int)) as total_new_tests_by_location
FROM Portfolio_Project..CovidVaccinations$
WHERE continent is NOT NULL
GROUP BY location


SELECT d.location, SUM(CAST(d.new_deaths as int)) as New_Deaths
FROM Portfolio_Project..CovidDeaths$ d
JOIN Portfolio_Project..CovidVaccinations$ v
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent is NOT NULL
AND d.new_deaths is NOT NULL
GROUP BY d.location
ORDER BY 1