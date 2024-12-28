# Netflix Movies and TV Shows Analysis by SQL
![Netflix Logo](https://github.com/Mohamed-Arafaath/Netflix_Analysis_SQL/blob/main/Netflix_2015_logo.svg)

## Overview
This project involves a comprehensive analysis of Netflix's movies and TV shows data using SQL. The goal is to extract valuable insights and answer various business questions based on the dataset. The following README provides a detailed account of the project's objectives, business problems, solutions, findings, and conclusions.

## Objectives
- Analyze the distribution of content types (movies vs TV shows).
- Identify the most common ratings for movies and TV shows.
- List and analyze content based on release years, countries, and durations.
- Explore and categorize content based on specific criteria and keywords.

## Dataset
The data for this project is sourced from the Kaggle dataset:
- Dataset Link: [Movies Dataset](https://www.kaggle.com/datasets/shivamb/netflix-shows?resource=download)

## Schema
```sql
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
```
## Business Problems and Solutions
# 1. Count the Number of Movies vs TV Shows
```sql
select movie_type, count(movie_type) as movies
from Netflix
Group by movie_type
```
# Objective: Determine the distribution of content types on Netflix.

# 1. Count the Number of Movies vs TV Shows
```sql
select movie_type, count(movie_type) as movies
from Netflix
Group by movie_type
```
# Objective: Determine the distribution of content types on Netflix.

# 2. Find the Most Common Rating for Movies and TV Shows
```sql
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
```
# Objective: Identify the most frequently occurring rating for each type of content.

# 3. List All Movies Released in a Specific Year (e.g., 2020)
```sql
select n.title
from Netflix n
where n.movie_type='Movie' and n.release_year = 2020
```
# Objective: Retrieve all movies released in a specific year.

# 4. Find the Top 5 Countries with the Most Content on Netflix
```sql
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
```
# Objective: Identify the top 5 countries with the highest number of content items.

# 5. Identify the longest movie
```sql
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
 -----OR SIMPLY----
select * 
from netflix
where movie_type='Movie' and
	duration = (select max(duration) from netflix)
```
# Objective: Find the movie with the longest duration.

# 6. Find Content Added in the Last 5 Years 
```sql
select *
from netflix
where datediff(year, date_added, CURRENT_TIMESTAMP) <= 5
```
# Objective: Retrieve content added to Netflix in the last 5 years.

# 7. Find All Movies/TV Shows by Director 'Rajiv Chilaka'
```sql
select *
from netflix
cross apply string_split(director, ',')
where value = 'Rajiv Chilaka'
----OR----
select *
from netflix
where director like '%Rajiv Chilaka%'
```
# Objective: List all content directed by 'Rajiv Chilaka'.

# 8. List All TV Shows with More Than 5 Seasons
```sql
select *
from netflix
cross apply string_split(duration, ' ')
where movie_type = 'TV Show' and value>'5' and value not like '%Season%'
order by title 
```
# Objective: Identify TV shows with more than 5 seasons.

# 9. Count the Number of Content Items in Each Genre
```sql
select trim(value) as genre, count(*) as count
from netflix
cross apply string_split(listed_in, ',')
group by trim(value)
order by trim(value)
```
# Objective: Count the number of content items in each genre.

# 10.Find each year and the average numbers of content release in India on netflix.
# Return top 5 year with highest avg content release!
```sql
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
```
# Objective: Calculate and rank years by the average number of content releases by India.

# 11. List All Movies that are Documentaries
```sql
select *
from netflix
where movie_type='Movie' and listed_in like '%ocumentaries%'
```
# Objective: Retrieve all movies classified as documentaries.

# 12. Find All Content Without a Director
```sql
select *
from netflix
where director IS NULL or director=''
```
# Objective: List content that does not have a director.

# 13. Find How Many Movies Actor 'Salman Khan' Appeared in the Last 10 Years
```sql
select * --count(*) as count
from netflix
where movie_type='Movie' and lower(cast) like '%salman khan%' and release_year >= year(CURRENT_TIMESTAMP)-10
```
# Objective: Count the number of movies featuring 'Salman Khan' in the last 10 years.

# 14. Find the Top 10 Actors Who Have Appeared in the Highest Number of Movies Produced in India
```sql
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
```
# Objective: Identify the top 10 actors with the most appearances in Indian-produced movies.

# 15. Categorize Content Based on the Presence of 'Kill' and 'Violence' Keywords
```sql
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
```
# Objective: Categorize content as 'Bad' if it contains 'kill' or 'violence' and 'Good' otherwise. Count the number of items in each category.

## Findings and Conclusion
- Content Distribution: The dataset contains a diverse range of movies and TV shows with varying ratings and genres.
- Common Ratings: Insights into the most common ratings provide an understanding of the content's target audience.
- Geographical Insights: The top countries and the average content releases by India highlight regional content distribution.
- Content Categorization: Categorizing content based on specific keywords helps in understanding the nature of content available on Netflix.
This analysis provides a comprehensive view of Netflix's content and can help inform content strategy and decision-making.








