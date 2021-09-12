use PortifolioProject;

-- Select Data that we are going to be using
select location, date, total_cases, new_cases, total_deaths, population
from PortifolioProject..CovidDeaths
order by 1,2

-- Looking at Total Cases vs Total Deaths
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from PortifolioProject..CovidDeaths
where location = 'Brazil'
order by 1,2

-- Total cases vs Population
select location, date, total_cases, population, (total_cases/population)*100 as ContaminationPercentage
from PortifolioProject..CovidDeaths
where location = 'Brazil'
order by 1,2

-- Looking at countries with highest infection rate compared to population
select location, max(total_cases) as HighestInfectionCount, max((total_cases/population))*100 as ContaminationPercentage
from PortifolioProject..CovidDeaths
group by location
order by 3 desc

-- Showing countries with death count per population
select location, max(cast(total_deaths as int)) as TotalDeathCount
from PortifolioProject..CovidDeaths
where continent is not null -- Remove Continents from query
group by location
order by 2 desc

-- Showing continents with highest death count
select location, max(cast(total_deaths as int)) as TotalDeathCount
from PortifolioProject..CovidDeaths
where continent is null -- Remove countries from query
group by location
order by 2 desc

-- GLOBAL NUMBERS
select date, 
sum(new_cases) GlobalCasesPerDay, 
sum(cast(new_deaths as int)) GlobalDeathsPerDay,
sum(cast(new_deaths as int))/sum(new_cases)*100 as GlobalDeathPercentage
from PortifolioProject..CovidDeaths
where continent is not null
group by date
order by 1

-- Looking at Total Population vs Vaccinations (Using CTE)
With PopVsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
From PortifolioProject..CovidDeaths dea
Join PortifolioProject..CovidVaccinations vac
	On dea.location = vac.location
	And dea.date = vac.date
where dea.continent is not null
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopVsVac

-- Looking at Total Population vs Vaccinations (Using Temp Table)
DROP Table if exists _PercentPopulationVaccinated
Create Table _PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date Datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert Into _PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
From PortifolioProject..CovidDeaths dea
Join PortifolioProject..CovidVaccinations vac
	On dea.location = vac.location
	And dea.date = vac.date
where dea.continent is not null

Select *, (RollingPeopleVaccinated/Population)*100 VaccinationPercentage
From _PercentPopulationVaccinated

-- Creating View to store data for later visualizations
Create View GlobalTotalDeathsByContinent as
	Select location, max(cast(total_deaths as int)) as TotalDeathCount
	From PortifolioProject..CovidDeaths
	Where continent is null -- Remove countries from query
	Group by location

SELECT * From GlobalTotalDeathsByContinent