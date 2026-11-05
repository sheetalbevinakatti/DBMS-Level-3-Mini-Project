USE patentpath_assignment;

-- 1. SELECT, filtering, and ORDER BY through the relational view.
SELECT invention_id, title, category, inventors, patent_count
FROM v_invention_catalog
WHERE category = 'Agriculture'
ORDER BY title ASC;

-- 2. JOIN across inventions, inventors, applications, and issued patents.
SELECT
  i.title AS invention,
  inv.name AS inventor,
  pa.application_number,
  pa.current_status AS application_status,
  p.patent_number,
  p.publication_date
FROM inventions AS i
JOIN patent_applications AS pa ON pa.invention_id = i.invention_id
JOIN inventors AS inv ON inv.inventor_id = pa.inventor_id
LEFT JOIN patents AS p ON p.application_id = pa.application_id
ORDER BY pa.filing_date DESC, i.title;

-- 3. Aggregate, GROUP BY, HAVING, and ORDER BY.
SELECT
  i.category,
  COUNT(DISTINCT i.invention_id) AS invention_count,
  COUNT(DISTINCT pa.application_id) AS application_count,
  COUNT(DISTINCT p.patent_id) AS patent_count
FROM inventions AS i
LEFT JOIN patent_applications AS pa ON pa.invention_id = i.invention_id
LEFT JOIN patents AS p ON p.application_id = pa.application_id
GROUP BY i.category
HAVING COUNT(DISTINCT i.invention_id) >= 1
ORDER BY patent_count DESC, invention_count DESC, i.category;

-- 4. Full-text search over invention titles, abstracts, and descriptions.
SELECT invention_id, title,
       MATCH(title, abstract, description)
         AGAINST ('soil moisture irrigation' IN NATURAL LANGUAGE MODE) AS relevance
FROM inventions
WHERE MATCH(title, abstract, description)
        AGAINST ('soil moisture irrigation' IN NATURAL LANGUAGE MODE)
ORDER BY relevance DESC
LIMIT 10;

-- 5. Nested subquery: inventions with more patents than the overall average.
SELECT i.invention_id, i.title, COUNT(p.patent_id) AS patent_count
FROM inventions AS i
LEFT JOIN patent_applications AS pa ON pa.invention_id = i.invention_id
LEFT JOIN patents AS p ON p.application_id = pa.application_id
GROUP BY i.invention_id, i.title
HAVING COUNT(p.patent_id) > (
  SELECT AVG(patent_counts.patent_count)
  FROM (
    SELECT COUNT(p2.patent_id) AS patent_count
    FROM inventions AS i2
    LEFT JOIN patent_applications AS pa2 ON pa2.invention_id = i2.invention_id
    LEFT JOIN patents AS p2 ON p2.application_id = pa2.application_id
    GROUP BY i2.invention_id
  ) AS patent_counts
);

-- 6. Correlated subquery: users with at least one patent application.
SELECT u.user_id, u.name, u.email
FROM users AS u
WHERE EXISTS (
  SELECT 1
  FROM inventors AS inv
  JOIN patent_applications AS pa ON pa.inventor_id = inv.inventor_id
  WHERE inv.user_id = u.user_id
)
ORDER BY u.name;

-- 7. Transactional DML demonstration. All changes are rolled back.
START TRANSACTION;
INSERT INTO searches (user_id, query_text, search_method)
VALUES (1, 'temporary DML demonstration', 'FULLTEXT');
SET @demo_search_id = LAST_INSERT_ID();
UPDATE searches
SET query_text = 'updated temporary DML demonstration'
WHERE search_id = @demo_search_id;
DELETE FROM searches
WHERE search_id = @demo_search_id;
ROLLBACK;

-- 8. Safe UPDATE and DELETE examples that leave the seed data unchanged.
START TRANSACTION;
UPDATE inventions
SET description = CONCAT(description, ' [temporary update demonstration]')
WHERE invention_id = 1;
DELETE FROM searches
WHERE search_id = 3;
ROLLBACK;

-- 9. Stored function example.
SELECT name, fn_patent_count_for_user(user_id) AS issued_patents
FROM users
ORDER BY issued_patents DESC, name;

-- 10. Stored procedure example: chronological status history for one application.
CALL sp_application_status_history(1);

-- 11. Stored procedure example: application totals by status for one user.
CALL sp_user_application_summary(1);

-- 12. Stored procedure example: application totals for every status, including zeroes.
CALL sp_application_status_summary();

-- 13. Stored procedure example: applications and issued patents for one invention.
CALL sp_invention_patent_details(1);

-- 14. Stored function example: application totals alongside issued patent totals.
SELECT
  name,
  fn_application_count_for_user(user_id) AS application_count,
  fn_patent_count_for_user(user_id) AS issued_patent_count
FROM users
ORDER BY application_count DESC, name;

-- 15. Stored procedure example: latest ten searches and their result counts.
CALL sp_user_search_history(1, 10);

-- 16. Stored procedure example: ranked patent matches for one saved search.
CALL sp_search_result_details(1);

-- 17. Stored procedure example: application status totals by invention category.
CALL sp_category_application_summary();

-- 18. Stored procedure example: inventors associated with one invention.
CALL sp_invention_inventor_list(1);

-- 19. Stored procedure example: published and unpublished patents by category.
CALL sp_patent_publication_summary();
