USE patentpath_assignment;

DROP TRIGGER IF EXISTS trg_application_status_after_insert;
DROP TRIGGER IF EXISTS trg_application_status_after_update;

DELIMITER $$

CREATE TRIGGER trg_application_status_after_insert
AFTER INSERT ON patent_applications
FOR EACH ROW
BEGIN
  INSERT INTO application_status_history (application_id, old_status, status, remarks)
  VALUES (NEW.application_id, NULL, NEW.current_status, 'Initial application status');
END$$

CREATE TRIGGER trg_application_status_after_update
AFTER UPDATE ON patent_applications
FOR EACH ROW
BEGIN
  IF OLD.current_status <> NEW.current_status THEN
    INSERT INTO application_status_history (application_id, old_status, status, remarks)
    VALUES (
      NEW.application_id,
      OLD.current_status,
      NEW.current_status,
      CONCAT('Status changed from ', OLD.current_status, ' to ', NEW.current_status)
    );
  END IF;
END$$

DELIMITER ;
