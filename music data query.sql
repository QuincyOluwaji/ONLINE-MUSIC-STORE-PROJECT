-----         Viewing the data

select * from album$
select * from artist$
select * from customer$
select * from employee$
select * from genre$
select * from invoice$
select * from invoice_line$
select * from media_type$
select * from playlist$
select * from playlist_track$
select * from track$

----    STAGE 1: DATA CLEANING
----    Checking for missing values in each tables

select album_id, title, artist_id 
from album$
where album_id is null 
or title is null
or artist_id is null

---           The album table has no null values

select * 
from artist$
where artist_id is null
or name is null
---           The table has no null values

select * 
from customer$
where customer_id is null 
or first_name is null
or last_name is null
or company is null
or address is null
or city is null
or state is null
or country is null
or postal_code is null
or phone is null
or fax is null
or email is null
or support_rep_id is null

-----       58 rows in this table have null values

---         Employee has 9 rows so i can see thee are no null values

select * 
from genre$
where genre_id is null
or name is null

---         The table has no null values

select * 
from invoice$
where invoice_id is null 
or customer_id is null
or invoice_date is null
or billing_address is null
or billing_city is null
or billing_state is null
or billing_country is null
or billing_postal_code is null
or total is null

----         The table has no null values

select * 
from invoice_line$
where invoice_line_id is null
or invoice_id is null
or track_id is null
or unit_price is null
or quantity is null

-----         The table has no null values

select * 
from playlist_track$
where playlist_id is null
or track_id is null

----          The table has no null values

select *
from track$
where track_id is null
or name is null
or album_id is null
or media_type_id is null
or genre_id is null
or composer is null
or milliseconds is null
or bytes is null
or unit_price is null

----          The table has 977 null values

----          The State column in customer's table had 58 empty row, tried to fill them up with right states 
----           then i realized the countries had no states and it was not a mistake the rows were empty.
update customer$
set state = 'BW'
where city = 'Stuttgart'
and country = 'Germany'
       
----            dropped the composers column because it contained the null values and it is not needed for the analysis

alter table track$
drop column composer

	
---           Checking for duplicate values

select *
from (
select *, 
ROW_NUMBER() over(partition by album_id, title, artist_id order by album_id) as rownum
from album$ as al
) as bl
where rownum > 1 

select *
from (
select*, ROW_NUMBER() over(partition by  artist_id, name order by artist_id) as rownum
from artist$ as a
) as b
where rownum > 1

----- alternatively checking for duplicates could be done using this method

select customer_id, first_name,last_name, COUNT(*) 
from customer$
group by customer_id,first_name,last_name
having COUNT(*) > 1


select invoice_id, COUNT(*) 
from invoice$
group by  invoice_id
having count(*) > 1

select invoice_line_id, count(*) 
from invoice_line$
group by invoice_line_id
having count(*) > 1

select genre_id, name, count(*)
from genre$
group by genre_id,name
having COUNT(*) > 1

select track_id, count(*) 
from track$
group by track_id
having count(*) > 1

------      None of the columns have duplicate values


-----     STAGE 2:  Explaatory Analysis

-----  Q1: From the employee table, who is the highest ranking officer?

select top 1 * 
from employee$
order by levels desc

-----  Q2: Which countries have the most invoice?

select billing_country, COUNT(billing_country) as country
from invoice$
group by billing_country
order by count(billing_country) desc

---- Q3: What are the top 3 values of total invoices?

select top 3 total as top_3, * 
from invoice$
order by total desc

---- Q4: What city has the highest sum of invoice total?

select top 1 billing_city,  sum(total) as sum_of_total
from invoice$
group by billing_city
order by sum(total) desc

---  Q5: Who is the best customer? (i.e the customer that spent the most)

select top 1  ii.customer_id,first_name, last_name, sum(total) as sum_of_total
from invoice$ ii
join customer$ ci
on ii.customer_id = ci.customer_id
group by ii.customer_id,first_name, last_name
order by sum(total) desc

-----Q6: What are the email, first name, last name, genre of all Rock music listener( Order alpabetically by email)

select c.email, c.first_name, c.first_name, g.name
from customer$ c
join invoice$ i
on c.customer_id = i.customer_id
join invoice_line$ il
on i.invoice_id = il.invoice_id
join playlist_track$ p
on il.track_id = p.track_id
join track$ t
on p.track_id = t.track_id
join genre$ g
on t.genre_id = g.genre_id
where g.name = 'Rock'
group by c.email, c.first_name, c.first_name, g.name
order by c.email

---  Q7: What are the top 10 rock bands, artist's name and their total count of tracks?

select top 10 ar.name, ar.artist_id, COUNT(ar.artist_id) as count_of_tracks
from artist$ ar
join album$ al
on ar.artist_id = al.artist_id
join track$ t
on al.album_id = t.album_id
join genre$ g
on t.genre_id = g.genre_id
where g.name like 'Rock'
group by ar.artist_id, ar.name
order by count_of_tracks desc

---  Q8: what songs are longer than the aveage milliseconds?

select name, milliseconds
from track$
where milliseconds > (
select AVG(milliseconds)
from track$
)
order by milliseconds desc

--- Q9: Who are the top 20 selling artist( artists whose music were purchased the most)

select top 20 ar.artist_id, ar.name, sum(il.unit_price * il.quantity) as Total_amount
from invoice$ i
join invoice_line$ il
on i.invoice_id = il.invoice_id
join track$ t
on il.track_id = t.track_id
join album$ a
on t.album_id = a.album_id
join artist$ ar
on a.artist_id = ar.artist_id
group by ar.artist_id, ar.name
order by Total_amount desc

----- Q10:	Who are the top 10 fans of the top artist? From previous query, the top artist is Queen.


with best_selling_artist as (
select top 1 sum(il.unit_price * il.quantity) as Total_amount, ar.artist_id, ar.name
from invoice_line$ il
join track$ t
on il.track_id = t.track_id
join album$ a
on t.album_id = a.album_id
join artist$ ar
on a.artist_id = ar.artist_id
group by ar.artist_id, ar.name
order by Total_amount desc
)
select top 10 c.first_name, c.last_name, ar.name, sum(il.unit_price * il.quantity) as Total_amount
from invoice$ i
join customer$ c 
on i.customer_id = c.customer_id
join invoice_line$ il
on i.invoice_id = il.invoice_id
join track$ t
on il.track_id = t.track_id
join album$ a
on t.album_id = a.album_id
join artist$ ar
on a.artist_id = ar.artist_id 
join best_selling_artist bsa
on ar.artist_id = bsa.artist_id
group by c.first_name, c.last_name, ar.name
order by Total_amount desc, c.first_name desc

---- Q11:  who are the favourite artist of each customer?

with fave_artist as 
(
select c.first_name, c.last_name, ar.name, sum(il.unit_price * il.quantity) as Total_amount,
ROW_NUMBER() over(PARTITION by c.first_name, c.last_name order by  sum(il.unit_price * il.quantity) desc) 
as row_num
from invoice$ i
join customer$ c 
on i.customer_id = c.customer_id
join invoice_line$ il
on i.invoice_id = il.invoice_id
join track$ t
on il.track_id = t.track_id
join album$ a
on t.album_id = a.album_id
join artist$ ar
on a.artist_id = ar.artist_id 
group by c.first_name, c.last_name, ar.name
)
select * from fave_artist 
where row_num <= 1
order by first_name,last_name ,Total_amount desc


--- Q12:  What is the most popular genre in each country?

with top_country as 
(
select sum(il.quantity * il.unit_price) AS sales, i.billing_country, g.name,
ROW_NUMBER() OVER(PARTITION BY i.billing_country ORDER BY sum(il.quantity * il.unit_price) DESC) AS row_num 
from invoice$ i
join invoice_line$ il
on i.invoice_id = il.invoice_id
join track$ t
on il.track_id = t.track_id
join genre$ g
on t.genre_id = g.genre_id
group by i.billing_country,g.name
)
select * from top_country where row_num <= 1
order by sales desc


----  Q13: How much did each custome spend on music in each country?

with Customer_per_country as (
		select c.customer_id,first_name,last_name,billing_country,SUM(total) as total_spending,
	    ROW_NUMBER() over(PARTITION BY billing_country order by SUM(total) desc) as RowNo 
		from invoice$ i
		join customer$ c on c.customer_id = i.customer_id
		group by c.customer_id, first_name, last_name,billing_country
		)
select * from Customer_per_country where RowNo <= 1
order by billing_country,total_spending desc

------  Q14: what are the most purcased tracks?

select sum(il.unit_price * quantity) as sales, il.track_id,t.name, al.title,ar.name
from invoice_line$ il
join track$ t
on il.track_id = t.track_id
join album$ al
on t.album_id = al.album_id
join artist$ ar
on al.artist_id = ar.artist_id
group by il.track_id,t.name, al.title,ar.name
order by sales desc

------ Q15: What are the top 10 best selling albums

select top 10 sum(il.unit_price * quantity) as sales, al.album_id,al.title, ar.name
from invoice_line$ il
join track$ t
on il.track_id = t.track_id
join album$ al
on t.album_id = al.album_id
join artist$ ar
on al.artist_id = ar.artist_id
group by al.album_id,al.title, ar.name
order by sales desc

----- Q16: How many albums does each artist have?

select ar.artist_id,ar.name, count(al.artist_id) as num_of_albums
from album$ al
join artist$ ar
on al.artist_id = ar.artist_id
group by  ar.artist_id,ar.name
order by num_of_albums desc

----Q17: What is the most popular playlist have have?

select p.name, COUNT(pt.track_id) as song_total
from playlist$ p
join playlist_track$ pt
on p.playlist_id = pt.playlist_id
group by p.name
order by song_total desc

----- Q18; What is the most popular media type?

select m.name, COUNT(t.media_type_id) as type_total
from track$ t
join media_type$ m
on t.media_type_id = m.media_type_id
group by m.name
order by type_total desc

----- STAGE 3: EXPORT RESULTS FROM ANALYSIS

---- Top countries
select billing_country, COUNT(billing_country) as country, i.customer_id as customer_id
into top_countries
from invoice$ i
group by billing_country,i.customer_id
order by count(billing_country) desc

select * from playlist$
	----best selling tracks, artists and albums

select sum(il.unit_price * quantity) as sales, il.track_id as track_id,t.name as track_name , 
al.title as albums, art.name as artists,t.genre_id as genre,c.customer_id, concat(first_name,' ', last_name)
as customers_names, art.artist_id, p.playlist_id
into all_sales
from invoice$ i
join invoice_line$ il
on i.invoice_id = il.invoice_id
join track$ t
on il.track_id = t.track_id
join album$ al
on t.album_id = al.album_id
join artist$ art
on al.artist_id = art.artist_id
join customer$ c
on i.customer_id = c.customer_id
join playlist_track$ pt
on il.track_id = pt.track_id
join playlist$ p
on pt.playlist_id = p.playlist_id
group by il.track_id,t.name, al.title,art.name ,t.genre_id, c.customer_id,concat(first_name,' ', last_name), 
art.artist_id, p.playlist_id
order by sales desc


---- Biggest playlist
select distinct p.name, COUNT(pt.track_id) as song_count, p.playlist_id
into playlist
from playlist$ p
join playlist_track$ pt
on p.playlist_id = pt.playlist_id
group by p.name, p.playlist_id
order by song_count desc


----- the top genres
with top_country as 
(
select sum(il.quantity * il.unit_price) AS sales,  g.name,g.genre_id,
ROW_NUMBER() OVER(PARTITION BY g.name ORDER BY sum(il.quantity * il.unit_price) DESC) AS row_num 
from invoice$ i
join invoice_line$ il
on i.invoice_id = il.invoice_id
join track$ t
on il.track_id = t.track_id
join genre$ g
on t.genre_id = g.genre_id
group by g.name, g.genre_id
)
select * 
into genres_
from top_country 
where row_num <= 1
order by sales desc



---Total artists
select count(a.artist_id) as artist_count, a.artist_id
into artist_list
from artist$ a
group by a.artist_id
order by artist_count


--- total customers
select COUNT(c.customer_id) as customers_count, c.customer_id
into customers_count
from customer$ c
group by c.customer_id
