--CREATE TABLE NETFLIX FOR ANALYSIS AND LOAD FLAT FILE FROM KAGGLE
DROP TABLE IF EXISTS Netflix;
CREATE TABLE Netflix(
	show_id nvarchar(50) NOT NULL,
	movie_type nvarchar(50) NULL,
	title nvarchar(150) NULL,
	director nvarchar(250) NULL,
	cast nvarchar(1000) NULL,
	country nvarchar(150) NULL,
	date_added nvarchar(50) NULL,
	release_year int NULL,
	rating nvarchar(50) NULL,
	duration nvarchar(50) NULL,
	listed_in nvarchar(150) NULL,
	description nvarchar(300) NULL
);


-- 15, Business Problems 
--1. Count the number of Movies vs TV Shows
select movie_type, count(movie_type) as movies
from Netflix
Group by movie_type

--2. Find the most common rating for movies and TV shows
with temp as(
select movie_type, rating, count(rating) as common_rating_count,
	max(count(rating)) over(partition by movie_type) as max_rating_count
from Netflix
group by movie_type, rating
)

select movie_type, rating, common_rating_count
from temp
where common_rating_count = max_rating_count
order by movie_type, rating


--3. List all movies released in a specific year (e.g., 2020)
select n.title
from Netflix n
where n.movie_type='Movie' and n.release_year = 2020


--4. Find the top 5 countries with the most content on Netflix.
with temp as
(
SELECT trim(country_split.value) AS country, 
	count(show_id) as Content_Count,
	rank() over(order by count(show_id) desc) as rk
FROM Netflix
CROSS APPLY STRING_SPLIT(country, ',') as country_split
group by trim(country_split.value)
)
select country, Content_Count
from temp
where rk <= 5
order by Content_Count desc


--5. Identify the longest movie or TV show duration
with temp as (
select *, 
	rank() over(order by value desc) as rk
from netflix
cross apply string_split(duration, ' ') 
where movie_type='Movie' and value not like '%min%' --or use value<>'min'
)
select *
from temp
where rk = 1
order by title
 ----------------------or simply------------------------
select * 
from netflix
where movie_type='Movie' and
	duration = (select max(duration) from netflix)




--6. Find content added in the last 5 years
select *
from netflix
where datediff(year, date_added, CURRENT_TIMESTAMP) <= 5


--7. Find all the movies/TV shows by director 'Rajiv Chilaka'!
select *
from netflix
cross apply string_split(director, ',')
where value = 'Rajiv Chilaka'
------or---------------
select *
from netflix
where director like '%Rajiv Chilaka%'


--8. List all TV shows with more than 5 seasons
select *
from netflix
cross apply string_split(duration, ' ')
where movie_type = 'TV Show' and value>'5' and value not like '%Season%'
order by title 



--9. Count the number of content items in each genre
select trim(value) as genre, count(*) as count
from netflix
cross apply string_split(listed_in, ',')
group by trim(value)
order by trim(value)



--10. Find each year and the average numbers of content release in India on netflix.
--return top 5 year with highest avg content release !
with temp as(
select year(date_added) as year_added, count(show_id) as count,
	SUM(count(show_id)) over() as total_count,
	convert(decimal(10,2), (count(show_id)*100.0 /(SUM(count(show_id)) over()))) as avg_year_count
	--avg(count(show_id)) over(order by year(date_added) rows between 1 preceding and 1 following) as moving_avg,
	--sum(count(show_id)) over(order by year(date_added) rows unbounded preceding) as running_total
from netflix
CROSS APPLY STRING_SPLIT(country, ',')
where trim(value) = 'India'
group by year(date_added)
),
temp2 as (
select year_added, avg_year_count,
	rank() over(order by avg_year_count desc) as rk
from temp)
select *
from temp2
where rk<=5
order by rk



--11. List all movies that are documentaries
select *
from netflix
where movie_type='Movie' and listed_in like '%ocumentaries%'


--12. Find all content without a director
select *
from netflix
where director IS NULL or director=''


--13. Find how many movies actor 'Salman Khan' appeared in last 10 years!
select * --count(*) as count
from netflix
where movie_type='Movie' and lower(cast) like '%salman khan%' and release_year >= year(CURRENT_TIMESTAMP)-10

--14. Find the top 10 actors who have appeared in the highest number of movies produced in India
with temp as(
select trim(cast_split.value) as actor, count(trim(title_split.value)) as movieCount,
	rank() over(order by count(trim(title_split.value)) desc) as rk
from netflix
cross apply string_split(country, ',') as country_split
cross apply string_split(cast, ',') as cast_split
cross apply string_split(title, ',') as title_split
where movie_type='Movie' and trim(country_split.value)='India'
group by trim(cast_split.value)
)
select *
from temp
where rk<=10
--order by trim(cast_split.value)


--15. Categorize the content based on the presence of the keywords 'kill' and 'violence' in
--the description field. Label content containing these keywords as 'Bad' and all other
--content as 'Good'. Count how many items fall into each category
SELECT 
    CASE 
        WHEN LOWER(description) LIKE '%kill%' OR LOWER(description) LIKE '%violence%' THEN 'Bad'
        ELSE 'Good'
    END AS category,
    COUNT(*) AS count
FROM netflix
GROUP BY 
    CASE 
        WHEN LOWER(description) LIKE '%kill%' OR LOWER(description) LIKE '%violence%' THEN 'Bad'
        ELSE 'Good'
    END;
