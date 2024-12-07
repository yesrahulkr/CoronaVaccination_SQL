
select *
from PP1..CovidDeaths
order by 3,4

--select *
--from PP1..Vaccination
--order by 3,4

-- Select Data that we are going to be using

select location,  date, total_cases, new_cases, total_deaths, population
from PP1..CovidDeaths
order by 1,2

-- Looking at total cases vs total deaths
-- shows likelihood of dying if you cantract covid in your country
select location,  date, total_cases, total_deaths, (total_deaths/total_cases)*100 as deathpercentage
from PP1..CovidDeaths
where location like '%states%'
order by 1,2

--Looking at total cases vs population
-- Shows what percentage of population got covid
select location,  date, population, total_cases, (total_cases/population)*100 as percentpopulation
from PP1..CovidDeaths
where location like '%states%'
order by 1,2


-- Looking at countries with highest infection rate compared to population
select location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as percentpopulationInfected
from PP1..CovidDeaths
--where location like '%states%'
group by location, population
order by percentpopulationInfected desc

--Showing countries with highest death count per population
select location, MAX(Cast(total_deaths as int)) as TotalDeathCount
from PP1..CovidDeaths
--where location like '%states%'
group by location, population
order by TotalDeathCount desc

-- Lets break things down by continent
select continent, MAX(Cast(total_deaths as int)) as TotalDeathCount
from PP1..CovidDeaths
--where location like '%states%'
where continent is not null
group by continent
order by TotalDeathCount desc

select *
from PP1..CovidDeaths
where continent is not null

-- showing continents with the highest death count per population
select continent, MAX(Cast(total_deaths as int)) as TotalDeathCount
from PP1..CovidDeaths
--where location like '%states%'
where continent is not null
group by continent
order by TotalDeathCount desc

-- Global Number
select SUM(new_cases) as newcase, SUM(cast(new_deaths as int)) as newdeath, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as death_percent -- total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage
from PP1..CovidDeaths
--where location like '%states%'
where continent is not null
--group by date
order by 1,2

select *
from PP1..Vaccination

-- Looking at total population vs Vaccination
select *
from PP1..CovidDeaths cd
JOIN PP1..Vaccination vc
ON cd.location = vc.location
AND cd.date = vc.date

select cd.continent, cd.location, cd.date, cd.population, 
vc.new_vaccinations, SUM(cast(vc.new_vaccinations as int))
over (partition by cd.location order by cd.location, cd.date) as RollingPeopleVaccinated 
, (RollingPeopleVaccinated/population)*100
from PP1..CovidDeaths cd
JOIN PP1..Vaccination vc
ON cd.location = vc.location
AND cd.date = vc.date
where cd.continent is not null
order by 2,3

SELECT 
    cd.continent, 
    cd.location, 
    cd.date, 
    cd.population, 
    vc.new_vaccinations, 
    SUM(CAST(vc.new_vaccinations AS INT)) 
        OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS RollingPeopleVaccinated,
    (SUM(CAST(vc.new_vaccinations AS INT)) 
        OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) / CAST(cd.population AS DECIMAL)) * 100 AS VaccinationPercentage
FROM PP1..CovidDeaths cd
JOIN PP1..Vaccination vc
    ON cd.location = vc.location
    AND cd.date = vc.date
WHERE cd.continent IS NOT NULL
ORDER BY 2, 3;


WITH PopVsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated, VaccinationPercentage)
as
(
SELECT 
    cd.continent, 
    cd.location, 
    cd.date, 
    cd.population, 
    vc.new_vaccinations, 
    SUM(CAST(vc.new_vaccinations AS INT)) 
        OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS RollingPeopleVaccinated
--    (SUM(CAST(vc.new_vaccinations AS INT)) 
       -- OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) / CAST(cd.population AS DECIMAL)) * 100 AS VaccinationPercentage
FROM PP1..CovidDeaths cd
JOIN PP1..Vaccination vc
    ON cd.location = vc.location
    AND cd.date = vc.date
WHERE cd.continent IS NOT NULL
--ORDER BY 2, 3
)
select *
from PopVsVac

--TEMP TABLE
DROP Table if exists #PercentPopulationVaccinated

create Table #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

insert into #PercentPopulationVaccinated
select cd.continent, cd.location, cd.date, cd.population, 
vc.new_vaccinations, SUM(cast(vc.new_vaccinations as int))
over (partition by cd.location order by cd.location, cd.date) as RollingPeopleVaccinated 
-- (RollingPeopleVaccinated/population)*100
from PP1..CovidDeaths cd
JOIN PP1..Vaccination vc
ON cd.location = vc.location
AND cd.date = vc.date
--where cd.continent is not null
--order by 2,3

select *, (RollingPeopleVaccinated/Population)*100
from #PercentPopulationVaccinated

-- creating view to store data for later visualization

create view PercentPopulationVaccinated as
select cd.continent, cd.location, cd.date, cd.population, 
vc.new_vaccinations, SUM(cast(vc.new_vaccinations as int))
over (partition by cd.location order by cd.location, cd.date) as RollingPeopleVaccinated 
-- (RollingPeopleVaccinated/population)*100
from PP1..CovidDeaths cd
JOIN PP1..Vaccination vc
ON cd.location = vc.location
AND cd.date = vc.date
where cd.continent is not null
--order by 2,3

SELECT * FROM information_schema.role_table_grants
WHERE table_name = 'PercentPopulationVaccinated';

select * from PercentPopulationVaccinated
