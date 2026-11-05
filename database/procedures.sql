USE patentpath_assignment;

DROP PROCEDURE IF EXISTS sp_update_application_status;
DROP PROCEDURE IF EXISTS sp_application_status_history;
DROP PROCEDURE IF EXISTS sp_user_application_summary;
DROP PROCEDURE IF EXISTS sp_application_status_summary;
DROP PROCEDURE IF EXISTS sp_invention_patent_details;
DROP PROCEDURE IF EXISTS sp_user_search_history;
DROP PROCEDURE IF EXISTS sp_search_result_details;
DROP PROCEDURE IF EXISTS sp_category_summary;
DROP FUNCTION IF EXISTS fn_application_count_for_user;
DROP FUNCTION IF EXISTS fn_patent_count_for_user;

DELIMITER $$

CREATE PROCEDURE sp_application_status_summary()
BEGIN
  SELECT statuses.status, COUNT(pa.application_id) AS application_count
  FROM (
    SELECT 'DRAFT' AS status
    UNION ALL SELECT 'FILED'
    UNION ALL SELECT 'UNDER_REVIEW'
    UNION ALL SELECT 'APPROVED'
    UNION ALL SELECT 'REJECTED'
  ) AS statuses
  LEFT JOIN patent_applications AS pa ON pa.current_status = statuses.status
  GROUP BY statuses.status
  ORDER BY FIELD(statuses.status, 'DRAFT', 'FILED', 'UNDER_REVIEW', 'APPROVED', 'REJECTED');
END$$

CREATE PROCEDURE sp_invention_patent_details(
  IN p_invention_id BIGINT UNSIGNED
)
BEGIN
  IF p_invention_id IS NULL OR NOT EXISTS (
    SELECT 1 FROM inventions WHERE invention_id = p_invention_id
  ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invention does not exist';
  END IF;

  SELECT
    i.invention_id,
    i.title AS invention_title,
    pa.application_id,
    pa.application_number,
    pa.current_status,
    p.patent_id,
    p.patent_number,
    p.title AS patent_title,
    p.publication_date
  FROM inventions AS i
  LEFT JOIN patent_applications AS pa ON pa.invention_id = i.invention_id
  LEFT JOIN patents AS p ON p.application_id = pa.application_id
  WHERE i.invention_id = p_invention_id
  ORDER BY pa.filing_date, pa.application_id;
END$$

CREATE PROCEDURE sp_user_search_history(
  IN p_user_id BIGINT UNSIGNED,
  IN p_limit INT UNSIGNED
)
BEGIN
  IF p_user_id IS NULL OR NOT EXISTS (
    SELECT 1 FROM users WHERE user_id = p_user_id
  ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'User does not exist';
  END IF;

  IF p_limit IS NULL OR p_limit < 1 OR p_limit > 100 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Search history limit must be between 1 and 100';
  END IF;

  SELECT
    s.search_id,
    s.query_text,
    s.search_method,
    s.searched_at,
    COUNT(DISTINCT sr.result_id) AS result_count
  FROM searches AS s
  LEFT JOIN search_results AS sr ON sr.search_id = s.search_id
  WHERE s.user_id = p_user_id
  GROUP BY s.search_id, s.query_text, s.search_method, s.searched_at
  ORDER BY s.searched_at DESC, s.search_id DESC
  LIMIT p_limit;
END$$

CREATE PROCEDURE sp_search_result_details(
  IN p_search_id BIGINT UNSIGNED
)
BEGIN
  IF p_search_id IS NULL OR NOT EXISTS (
    SELECT 1 FROM searches WHERE search_id = p_search_id
  ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Search does not exist';
  END IF;

  SELECT
    s.search_id,
    s.query_text,
    sr.result_rank,
    sr.similarity_score,
    p.patent_id,
    p.patent_number,
    p.title AS patent_title,
    i.invention_id,
    i.title AS invention_title
  FROM searches AS s
  JOIN search_results AS sr ON sr.search_id = s.search_id
  JOIN patents AS p ON p.patent_id = sr.patent_id
  JOIN patent_applications AS pa ON pa.application_id = p.application_id
  JOIN inventions AS i ON i.invention_id = pa.invention_id
  WHERE s.search_id = p_search_id
  ORDER BY sr.result_rank;
END$$

CREATE PROCEDURE sp_update_application_status(
  IN p_application_id BIGINT UNSIGNED,
  IN p_new_status VARCHAR(20)
)
BEGIN
  IF p_new_status IS NULL
     OR p_new_status NOT IN ('DRAFT', 'FILED', 'UNDER_REVIEW', 'APPROVED', 'REJECTED') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Unsupported patent application status';
  END IF;

  UPDATE patent_applications
  SET current_status = p_new_status
  WHERE application_id = p_application_id;

  IF ROW_COUNT() = 0 AND NOT EXISTS (
    SELECT 1 FROM patent_applications WHERE application_id = p_application_id
  ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Patent application does not exist';
  END IF;
END$$

CREATE PROCEDURE sp_application_status_history(
  IN p_application_id BIGINT UNSIGNED
)
BEGIN
  IF p_application_id IS NULL OR NOT EXISTS (
    SELECT 1 FROM patent_applications WHERE application_id = p_application_id
  ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Patent application does not exist';
  END IF;

  SELECT status_history_id, old_status, status, changed_at, remarks
  FROM application_status_history
  WHERE application_id = p_application_id
  ORDER BY changed_at, status_history_id;
END$$

CREATE PROCEDURE sp_user_application_summary(
  IN p_user_id BIGINT UNSIGNED
)
BEGIN
  IF p_user_id IS NULL OR NOT EXISTS (
    SELECT 1 FROM users WHERE user_id = p_user_id
  ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'User does not exist';
  END IF;

  SELECT
    u.user_id,
    u.name,
    COUNT(pa.application_id) AS application_count,
    COUNT(CASE WHEN pa.current_status = 'DRAFT' THEN pa.application_id END) AS draft_count,
    COUNT(CASE WHEN pa.current_status = 'FILED' THEN pa.application_id END) AS filed_count,
    COUNT(CASE WHEN pa.current_status = 'UNDER_REVIEW' THEN pa.application_id END) AS under_review_count,
    COUNT(CASE WHEN pa.current_status = 'APPROVED' THEN pa.application_id END) AS approved_count,
    COUNT(CASE WHEN pa.current_status = 'REJECTED' THEN pa.application_id END) AS rejected_count
  FROM users AS u
  LEFT JOIN inventors AS inv ON inv.user_id = u.user_id
  LEFT JOIN patent_applications AS pa ON pa.inventor_id = inv.inventor_id
  WHERE u.user_id = p_user_id
  GROUP BY u.user_id, u.name;
END$$

CREATE PROCEDURE sp_category_summary()
BEGIN
  SELECT
    i.category,
    COUNT(DISTINCT i.invention_id) AS invention_count,
    COUNT(DISTINCT pa.application_id) AS application_count,
    COUNT(DISTINCT p.patent_id) AS patent_count
  FROM inventions AS i
  LEFT JOIN patent_applications AS pa ON pa.invention_id = i.invention_id
  LEFT JOIN patents AS p ON p.application_id = pa.application_id
  GROUP BY i.category
  ORDER BY invention_count DESC, i.category;
END$$

CREATE FUNCTION fn_application_count_for_user(p_user_id BIGINT UNSIGNED)
RETURNS INT UNSIGNED
READS SQL DATA
BEGIN
  DECLARE v_application_count INT UNSIGNED DEFAULT 0;

  SELECT COUNT(DISTINCT pa.application_id)
  INTO v_application_count
  FROM inventors AS inv
  JOIN patent_applications AS pa ON pa.inventor_id = inv.inventor_id
  WHERE inv.user_id = p_user_id;

  RETURN v_application_count;
END$$

CREATE FUNCTION fn_patent_count_for_user(p_user_id BIGINT UNSIGNED)
RETURNS INT UNSIGNED
READS SQL DATA
BEGIN
  DECLARE v_patent_count INT UNSIGNED DEFAULT 0;

  SELECT COUNT(DISTINCT p.patent_id)
  INTO v_patent_count
  FROM inventors AS inv
  JOIN patent_applications AS pa ON pa.inventor_id = inv.inventor_id
  JOIN patents AS p ON p.application_id = pa.application_id
  WHERE inv.user_id = p_user_id;

  RETURN v_patent_count;
END$$

DELIMITER ;
