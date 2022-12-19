/*
Covid 19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
Download the source files from https://ourworldindata.org/covid-deaths
Import the xls or csv files into tables
*/
-- Check the tables if the count and data matches with source files.
select * from PortfolioProjects..CovidDeaths;
select * from PortfolioProjects..CovidVaccinations;

select count(*) from PortfolioProjects..CovidDeaths; --242940
select count(*) from PortfolioProjects..CovidVaccinations; --242940


select location, date, total_cases, new_cases, total_deaths, population
from PortfolioProjects..CovidDeaths
order by 1, 2

-- total cases vs total deaths
-- shows likelihood of dying if you contract covid in your country
select location, date, total_cases, total_deaths, (cast (total_deaths as float)/cast(total_cases as float))*100 as death_percentage
from PortfolioProjects..CovidDeaths
where continent is not null 
order by 1, 2

-- total cases vs population
-- shows what percentage of population got covid in unites states
select location, date, population, total_cases, (cast (total_cases as float)/cast(population as float))*100 as percentage_population_infected
from PortfolioProjects..CovidDeaths
where location like '%states%'
and continent is not null
order by 1, 2

-- Looking at the Countries with highest infection rate compared to population
select location, population, max(total_cases) as highest_infection_count, max(cast (total_cases as float)/cast(population as float))*100 as percentage_population_infected
from PortfolioProjects..CovidDeaths
where location like '%states%'
and  continent is not null
group by location, population
order by percentage_population_infected desc 

-- break up by continents
-- Showing continents with highest death count per population
select continent, max(total_deaths) as total_death_count
from PortfolioProjects..CovidDeaths
where continent is not null
group by continent
order by total_death_count desc 

-- GLOBAL NUMBERS

Select sum(new_cases) as total_cases, 
sum(new_deaths) as total_deaths,
sum(cast(new_deaths as float)) / sum(cast (new_cases as float)) *100  as death_percentage
From PortfolioProjects..CovidDeaths
where continent is not null 
order by 1,2
--650171777	6624054	1.01881598591752

-- Total Population vs Vaccinations
-- demonstrate rolling count
select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
sum(cast(cv.new_vaccinations as float)) over (partition by cd.location order by cd.location, cd.date) as rolling_people_vaccinated
from PortfolioProjects..CovidDeaths cd
join PortfolioProjects..CovidVaccinations cv
	on cd.location = cv.location
	and cd.date = cv.date
where cd.continent is not null
order by 2,3

-- Shows Percentage of Population that has recieved at least one Covid Vaccine
-- demonstrate cte
with cte as (
select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
sum(cast(cv.new_vaccinations as float)) over (partition by cd.location order by cd.location, cd.date) as rolling_people_vaccinated
from PortfolioProjects..CovidDeaths cd
join PortfolioProjects..CovidVaccinations cv
	on cd.location = cv.location
	and cd.date = cv.date
where cd.continent is not null
)
select *, (rolling_people_vaccinated/population)*100 from cte order by 2,3

-- using Temp table

drop table if exists #percent_population_vaccinated
create table #percent_population_vaccinated
(
continent varchar(50),
Location varchar(50),
date datetime,
population int,
new_vaccinations varchar(50),
rolling_people_vaccinated float
)

insert into #percent_population_vaccinated
select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
sum(cast(cv.new_vaccinations as float)) over (partition by cd.location order by cd.location, cd.date) as rolling_people_vaccinated
from PortfolioProjects..CovidDeaths cd
join PortfolioProjects..CovidVaccinations cv
	on cd.location = cv.location
	and cd.date = cv.date
where cd.continent is not null

select *, (rolling_people_vaccinated/population)*100 from #percent_population_vaccinated order by 2,3


-- creating view to store data for later visualization
create view percent_population_vaccinated as
select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
sum(cast(cv.new_vaccinations as float)) over (partition by cd.location order by cd.location, cd.date) as rolling_people_vaccinated
from PortfolioProjects..CovidDeaths cd
join PortfolioProjects..CovidVaccinations cv
	on cd.location = cv.location
	and cd.date = cv.date
where cd.continent is not null

select * from percent_population_vaccinated