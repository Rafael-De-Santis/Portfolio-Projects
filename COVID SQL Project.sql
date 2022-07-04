SELECT * 
FROM PortfolioProject..CovidDeaths
where continent is not null
order by 3,4

--SELECT * 
--FROM PortfolioProject..CovidVaccinations
--order by 3,4

Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
order by 1,2

-- Looking at Total Cases vs Total Deaths
-- Shows the likelihood of dying if you contract covid in your country
Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where location like '%states%'
--Where location like '%nezuela%'
order by 1,2 
--order by DeathPercentage Desc

-- Looking at the Total Cases vs Population

Select Location, date, total_cases, population, (total_deaths/population)*100 as PopulationInfectedPercentage
From PortfolioProject..CovidDeaths
--Where location like '%states%'
order by 1,2 


--Looking at countries wit highest infection rate compared to Population

Select Location, MAX(total_cases) as HighestInfectionCount, population, MAX((total_cases/population))*100 as PopulationInfectedPercentage
From PortfolioProject..CovidDeaths
GROUP BY Location, population
order by PopulationInfectedPercentage DESC

--Showing Countries with highest Death Count per Population
--we gonna cast the total deaths to INT because it was varchar255
--because with the varchar we were not seeing the right numbers
Select Location, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
--we are using not null here because we dont want the rows with the locations as continents
Where continent is not null
GROUP BY Location
order by TotalDeathCount DESC

--LET'S BREAK THINGS DOWN BY CONTINENT
--this is by location
Select location, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is null
Group by location
order by TotalDeathCount desc

--by continent
-- Showing continents with the highest deeath count per location
Select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is not null
Group by continent
order by TotalDeathCount desc

--GLOBAL NUMBERS
--we are using new cases and sum them to get the total cases in a easier way
--we have to cast on new deaths because is a varchar (we have to cast it everytime we wanna use it)
--and we are adding the percentages
Select  date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where continent is not null
Group by date
order by 1,2 

--removing the date and group by we ge the total of global cases
Select  SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where continent is not null
--Group by date
order by 1,2 


--Using Joins within the tables

Select * 
from PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date

--Looking total population vs Vaccinations
--we are using another form of CAST which is COVERT( int,
--using Over Partition by location
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by  dea.location order by dea.location,
dea.date) as RollingPeopleVaccinated
--, MAX(RollingPeopleVaccinated/population*100
--we can't use the rollingpeoplevaccinated, right here,
--so we are going to do a CTE in the next query
from PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

--USE CTE
--if the number of columns in the cte is different than the query below it gonna give you an error
with PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by  dea.location order by dea.location,
dea.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)
Select*, (RollingPeopleVaccinated/population)*100
From PopvsVac

--TEMP TABLE
--if we want to modify/ or make alterations or something we havce to use drop table if exists
--Its like recreating the table with the new changes
--if not we gonna get an error
DROP Table if exists #PercentPopulationVaccinated
Create table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by  dea.location order by dea.location,
dea.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3
Select*, (RollingPeopleVaccinated/population)*100
From #PercentPopulationVaccinated


-- Creating View to store data for later visualizations
--DROP VIEW [PercentPopulationVaccinated];
--sometimes when you create a view is going to be create in the master db by default
--you have to run USE databasename to see it in the database you want
-- ej: use PortfolioProject

Create View PercentPopulationVaccinated as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by  dea.location order by dea.location,
dea.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)

Select *
From PercentPopulationVaccinated