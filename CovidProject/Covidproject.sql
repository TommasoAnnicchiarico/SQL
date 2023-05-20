CREATE DATABASE CovidProject;
USE CovidProject;


-- Looking at total cases vs total deaths: Show likelihood of dying if you contract covid
SELECT 
    location,
    date,
    total_cases,
    total_deaths,
    (total_deaths / total_cases) * 100 AS death_percentage
FROM coviddeaths
ORDER BY location ASC , date ASC , death_percentage DESC;


-- Looking at total cases vs population: show what percentage of population got covid
SELECT 
    location,
    date,
    total_cases,
    population,
    (total_cases / population) * 100 AS infection_rate
FROM coviddeaths
ORDER BY location, date;


-- Countries with highest infection rate per population
SELECT 
    location,
    population,
    MAX(total_cases) AS Highest_infection_count,
    MAX(total_cases / population) * 100 AS population_infected_percentage
FROM coviddeaths
GROUP BY location , population
ORDER BY population_infected_percentage DESC;


-- Showing the countries with highest deathcount per population
SELECT 
    location,
    MAX(CAST(COALESCE(total_deaths, 0) AS UNSIGNED)) AS total_death_count
FROM coviddeaths
GROUP BY location
ORDER BY total_death_count DESC;


-- Breaking down by Continent and showing highest totaldeaths continent
SELECT 
    continent,
    MAX(CAST(COALESCE(total_deaths, 0) AS UNSIGNED)) AS total_death_count
FROM coviddeaths
GROUP BY continent
ORDER BY total_death_count DESC;


-- Looking at GLOBAL numbers per day
SELECT 
    date,
    SUM(total_cases),
    SUM(total_deaths),
    (SUM(total_deaths) / SUM(total_cases)) * 100 AS death_percentage
FROM coviddeaths
GROUP BY date
ORDER BY date ASC , death_percentage DESC;


-- Calculating KPI of GLOBAL numbers 
SELECT 
    SUM(total_cases) AS total_cases,
    SUM(total_deaths) AS total_deaths,
    (SUM(total_deaths) / SUM(total_cases)) * 100 AS death_percentage
FROM coviddeaths;


-- Looking at total Population vs Vaccinations
SELECT 
coviddeaths.continent, 
coviddeaths.location, 
coviddeaths.date, 
coviddeaths.population, 
covidvaccination.new_vaccinations,
SUM(covidvaccination.new_vaccinations) OVER(PARTITION BY location ORDER BY coviddeaths.location,coviddeaths.date) AS rolling_count
FROM coviddeaths
JOIN covidvaccination ON covidvaccination.location=coviddeaths.location AND
covidvaccination.date=coviddeaths.date
ORDER BY coviddeaths.continent;


-- USE CTE to further utilize the rolling_count column
WITH PopvsVac
AS 
(SELECT 
coviddeaths.continent, 
coviddeaths.location, 
coviddeaths.date, 
coviddeaths.population, 
covidvaccination.new_vaccinations,
SUM(covidvaccination.new_vaccinations) OVER(PARTITION BY location ORDER BY coviddeaths.location,coviddeaths.date) AS rolling_count
FROM coviddeaths
JOIN covidvaccination ON covidvaccination.location=coviddeaths.location AND
covidvaccination.date=coviddeaths.date
ORDER BY coviddeaths.continen)
SELECT continent, 
location, 
date, 
population, 
new_vaccinations, 
rolling_count,
(rolling_count/population)*100
FROM PopvsVac
ORDER BY location;