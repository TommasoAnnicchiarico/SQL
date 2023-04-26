-- BUSINESS QUESTIONS #1 : Find the 5 5 oldest users
SELECT * FROM users 
ORDER BY created_at ASC
LIMIT 5;


-- BUSINESS QUESTIONS #2 : What is the most popular registration day?
SELECT 
    DATE_FORMAT(created_at, '%W') AS dayoftheweek,
    COUNT(*) AS total
FROM
    users
GROUP BY dayoftheweek
ORDER BY total DESC;


-- BUSINESS QUESTIONS #3 : Find inactive user (students who never posted a photo)
SELECT username FROM users
LEFT JOIN photos ON photos.user_id=users.id WHERE photos.id IS NULL;


-- BUSINESS QUESTIONS #4 : Who got the most like in a single post?
SELECT 
    users.id,
    users.username,
    photo_id,
    photos.image_url,
    COUNT(*) AS num_likes
FROM photos
        INNER JOIN likes ON likes.photo_id = photos.id
        INNER JOIN users ON users.id = photos.user_id
GROUP BY photo_id
ORDER BY num_likes DESC
LIMIT 1;


-- BUSINESS QUESTIONS #5 : Average number of photos per user
SELECT 
    AVG(posted) AS average_peruser
FROM
    (SELECT users.id, IFNULL(COUNT(photos.user_id), 0) AS posted
    FROM users
    LEFT JOIN photos ON photos.user_id = users.id
    GROUP BY users.id) a;


-- BUSINESS QUESTIONS #6 : 5 most commonly used hastag
SELECT 
    tag_id, tag_name, COUNT(tag_id) AS count_tag
FROM photo_tags
        INNER JOIN tags ON tags.id = photo_tags.tag_id
GROUP BY tag_id
ORDER BY count_tag DESC
LIMIT 5;


-- BUSINESS QUESTIONS #7 : find users that have liked every single photo on the site (possibly bots)
SELECT 
    username, COUNT(*) AS num_likes
FROM users
        INNER JOIN LIKES ON likes.user_id = users.id
GROUP BY likes.user_id
HAVING num_likes = (SELECT COUNT(*) FROM photos);