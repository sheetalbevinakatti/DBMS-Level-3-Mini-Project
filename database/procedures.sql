USE patentpath_assignment;

DROP PROCEDURE IF EXISTS sp_update_application_status;
DROP PROCEDURE IF EXISTS sp_category_summary;
DROP FUNCTION IF EXISTS fn_patent_count_for_user;

DELIMITER $$

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
