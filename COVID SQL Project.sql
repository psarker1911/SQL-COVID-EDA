-- Check number of reocrds in both tables

SELECT COUNT(iso_code) 
FROM SQLProject.COVIDDeaths  

-- 297,197

SELECT COUNT(iso_code)
FROM SQLProject.COVIDVaccinations

-- 297,197

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM SQLProject.COVIDDeaths
ORDER BY 1,2


-- Total cases VS Total Deaths

SELECT location, date, total_cases, total_deaths, population, (total_deaths/total_cases)*100 AS DeathPercentage
FROM SQLProject.COVIDDeaths
ORDER BY 1,2

-- Liklihood of dying from COVID as a percentage at given Country

SELECT location, date, total_cases, total_deaths, population, (total_deaths/total_cases)*100 AS DeathPercentage
FROM SQLProject.COVIDDeaths
WHERE location LIKE '%states'
ORDER BY 1,2




SELECT location, date, total_cases, total_deaths, population, (total_deaths/total_cases)*100 AS DeathPercentage
FROM SQLProject.COVIDDeaths
WHERE location = 'Australia'
ORDER BY 1,2


-- Total cases VS Population
-- What percentage got COVID

SELECT location, date, population, total_cases, (total_cases /population)*100 AS InfectedPercentage
FROM SQLProject.COVIDDeaths
WHERE location = 'Australia'
ORDER BY 1,2

-- Countries with Highest infection Rate compared to Population

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX(total_cases/population*100) AS InfectedPercentage
FROM SQLProject.COVIDDeaths
-- WHERE location = 'Australia'--
GROUP BY location, population
ORDER BY InfectedPercentage DESC

-- Countries with Highest Death Count per Population

SELECT location, MAX(total_deaths) AS TotalDeathCount
FROM SQLProject.COVIDDeaths
GROUP BY location
ORDER BY TotalDeathCount DESC

-- ^ no need to cast total_deaths from NVARCHAR to int as dbeaver changed it during import --

-- to fix location - add where clause

SELECT continent, MAX(total_deaths) AS TotalDeathCount
FROM SQLProject.COVIDDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- GLOBAL NUMBERS

SELECT date, SUM(new_cases) AS TotalCases, SUM(new_deaths) AS TotalDeaths, (SUM(new_deaths)/SUM(new_cases)*100) AS DeathPercentage
FROM SQLProject.COVIDDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date DESC

SELECT SUM(new_cases) AS TotalCases, SUM(new_deaths) AS TotalDeaths, (SUM(new_deaths)/SUM(new_cases)*100) AS DeathPercentage
FROM SQLProject.COVIDDeaths
WHERE continent IS NOT NULL
--GROUP BY date--
ORDER BY date DESC

--
SELECT dea.continent, dea.location, dea.date, dea.population, vacc.new_vaccinations
FROM `SQLProject`.`COVIDDeaths` dea
JOIN `SQLProject`.`COVIDVaccinations` vacc
    ON dea.location = vacc.location
    AND dea.date = vacc.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

-- Total Population VS Vaccinatations

SELECT dea.continent, dea.location, dea.date, dea.population, vacc.new_vaccinations
, SUM(vacc.new_vaccinations) OVER(PARTITION BY dea.location)
FROM `SQLProject`.`COVIDDeaths` dea
JOIN `SQLProject`.`COVIDVaccinations` vacc
    ON dea.location = vacc.location
    AND dea.date = vacc.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

--Count function starts over once it reaches new location when partitioning, therefore doesnt run perpetually

SELECT dea.continent, dea.location, dea.date, dea.population, vacc.new_vaccinations
, SUM(vacc.new_vaccinations) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.`date`) AS RollingPeopleVaxxed
FROM `SQLProject`.`COVIDDeaths` dea
JOIN `SQLProject`.`COVIDVaccinations` vacc
    ON dea.location = vacc.location
    AND dea.date = vacc.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

-- cannot calculated based on new column created 'RollingPeopleVaxxed' - need to create temp table or CTE
SELECT dea.continent, dea.location, dea.date, dea.population, vacc.new_vaccinations
, SUM(vacc.new_vaccinations) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.`date`) AS RollingPeopleVaxxed
, (RollingPeopleVaxxed/population)*100
FROM `SQLProject`.`COVIDDeaths` dea
JOIN `SQLProject`.`COVIDVaccinations` vacc
    ON dea.location = vacc.location
    AND dea.date = vacc.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3


-- USE CTE - # of colums in CTE must equal # of columns in SELECT statement

WITH PopVSVacc (continent, location, date, population, new_vaccinations, RollingPeopleVaxxed)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vacc.new_vaccinations
, SUM(vacc.new_vaccinations) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.`date`) AS RollingPeopleVaxxed
FROM `SQLProject`.`COVIDDeaths` dea
JOIN `SQLProject`.`COVIDVaccinations` vacc
    ON dea.location = vacc.location
    AND dea.date = vacc.date
WHERE dea.continent IS NOT NULL
-- ORDER BY 2,3 --
)
SELECT *, (RollingPeopleVaxxed/population)*100 AS VaccinationPercentage
FROM PopVSVacc 

-- Percentage population increases as more people get vaccinated, since population remains constant

-- To explore MAX function - would need to remove "date" column, keep location, population etc 

--

-- TEMP TABLE

-- Step 1: drop the table if it exists
DROP TEMPORARY TABLE IF EXISTS PercentPopulationVaccinated;

-- Step 2: create the table 
CREATE TEMPORARY TABLE PercentPopulationVaccinated
(
    Continent VARCHAR(255),
    Location VARCHAR(255),
    Date VARCHAR(50),
    Population BIGINT,
    New_vaccinations NUMERIC(18,2),
    RollingPeopleVaxxed NUMERIC(18,2)
);

-- Step 3: populate the table
INSERT INTO PercentPopulationVaccinated
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vacc.new_vaccinations,
    SUM(vacc.new_vaccinations) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.`date`) AS RollingPeopleVaxxed
FROM `SQLProject`.`COVIDDeaths` dea
JOIN `SQLProject`.`COVIDVaccinations` vacc
    ON dea.location = vacc.location
    AND dea.date = vacc.date
WHERE dea.continent IS NOT NULL
    AND vacc.new_vaccinations != ''; -- ignore rows with empty strings


-- Step 4: retrieve data from the table
SELECT *, (RollingPeopleVaxxed/Population)*100 AS VaccinationPercentage 
FROM PercentPopulationVaccinated;


-- Creating View to store data for visualisations

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vacc.new_vaccinations
, SUM(vacc.new_vaccinations) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.`date`) AS RollingPeopleVaxxed
FROM `SQLProject`.`COVIDDeaths` dea
JOIN `SQLProject`.`COVIDVaccinations` vacc
    ON dea.location = vacc.location
    AND dea.date = vacc.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3--

