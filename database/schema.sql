CREATE DATABASE IF NOT EXISTS patentpath_assignment
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;

USE patentpath_assignment;

CREATE TABLE IF NOT EXISTS users (
  user_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(254) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  role ENUM('USER', 'ADMIN') NOT NULL DEFAULT 'USER',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id),
  UNIQUE KEY uq_users_email (email)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS inventors (
  inventor_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(254) NOT NULL,
  affiliation VARCHAR(150) NULL,
  contact_number VARCHAR(30) NULL,
  address VARCHAR(255) NULL,
  PRIMARY KEY (inventor_id),
  UNIQUE KEY uq_inventors_user (user_id),
  UNIQUE KEY uq_inventors_email (email),
  CONSTRAINT fk_inventors_user
    FOREIGN KEY (user_id) REFERENCES users (user_id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS inventions (
  invention_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  title VARCHAR(150) NOT NULL,
  abstract TEXT NULL,
  description TEXT NULL,
  category VARCHAR(100) NOT NULL,
  created_by BIGINT UNSIGNED NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (invention_id),
  KEY idx_inventions_created_by (created_by),
  KEY idx_inventions_category (category),
  FULLTEXT KEY ft_inventions_content (title, abstract, description),
  CONSTRAINT fk_inventions_creator
    FOREIGN KEY (created_by) REFERENCES users (user_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT chk_inventions_title_not_blank CHECK (CHAR_LENGTH(TRIM(title)) > 0),
  CONSTRAINT chk_inventions_category_not_blank CHECK (CHAR_LENGTH(TRIM(category)) > 0)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS invention_inventors (
  invention_id BIGINT UNSIGNED NOT NULL,
  inventor_id BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (invention_id, inventor_id),
  CONSTRAINT fk_invention_inventors_invention
    FOREIGN KEY (invention_id) REFERENCES inventions (invention_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_invention_inventors_inventor
    FOREIGN KEY (inventor_id) REFERENCES inventors (inventor_id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS patent_applications (
  application_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  application_number VARCHAR(50) NOT NULL,
  invention_id BIGINT UNSIGNED NOT NULL,
  inventor_id BIGINT UNSIGNED NOT NULL,
  filing_date DATE NOT NULL,
  current_status ENUM('DRAFT', 'FILED', 'UNDER_REVIEW', 'APPROVED', 'REJECTED')
    NOT NULL DEFAULT 'DRAFT',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (application_id),
  UNIQUE KEY uq_applications_number (application_number),
  KEY idx_applications_invention (invention_id),
  KEY idx_applications_inventor (inventor_id),
  KEY idx_applications_status_filing (current_status, filing_date),
  CONSTRAINT fk_applications_invention
    FOREIGN KEY (invention_id) REFERENCES inventions (invention_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_applications_inventor
    FOREIGN KEY (inventor_id) REFERENCES inventors (inventor_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS application_status_history (
  status_history_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  application_id BIGINT UNSIGNED NOT NULL,
  old_status ENUM('DRAFT', 'FILED', 'UNDER_REVIEW', 'APPROVED', 'REJECTED') NULL,
  status ENUM('DRAFT', 'FILED', 'UNDER_REVIEW', 'APPROVED', 'REJECTED') NOT NULL,
  changed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  remarks VARCHAR(500) NULL,
  PRIMARY KEY (status_history_id),
  KEY idx_status_history_application_changed (application_id, changed_at),
  CONSTRAINT fk_status_history_application
    FOREIGN KEY (application_id) REFERENCES patent_applications (application_id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS patents (
  patent_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  application_id BIGINT UNSIGNED NOT NULL,
  patent_number VARCHAR(50) NOT NULL,
  title VARCHAR(200) NOT NULL,
  abstract TEXT NULL,
  filing_date DATE NOT NULL,
  publication_date DATE NULL,
  PRIMARY KEY (patent_id),
  UNIQUE KEY uq_patents_application (application_id),
  UNIQUE KEY uq_patents_number (patent_number),
  CONSTRAINT fk_patents_application
    FOREIGN KEY (application_id) REFERENCES patent_applications (application_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS searches (
  search_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  invention_id BIGINT UNSIGNED NULL,
  query_text VARCHAR(1000) NOT NULL,
  search_method ENUM('SEMANTIC', 'FULLTEXT') NOT NULL DEFAULT 'SEMANTIC',
  searched_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (search_id),
  KEY idx_searches_user_executed (user_id, searched_at),
  CONSTRAINT fk_searches_user
    FOREIGN KEY (user_id) REFERENCES users (user_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_searches_invention
    FOREIGN KEY (invention_id) REFERENCES inventions (invention_id)
    ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT chk_searches_query_not_blank CHECK (CHAR_LENGTH(TRIM(query_text)) > 0)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS search_results (
  result_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  search_id BIGINT UNSIGNED NOT NULL,
  patent_id BIGINT UNSIGNED NOT NULL,
  similarity_score DECIMAL(8, 7) NOT NULL,
  result_rank INT UNSIGNED NOT NULL,
  PRIMARY KEY (result_id),
  UNIQUE KEY uq_search_result_patent (search_id, patent_id),
  UNIQUE KEY uq_search_result_rank (search_id, result_rank),
  CONSTRAINT fk_search_results_search
    FOREIGN KEY (search_id) REFERENCES searches (search_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_search_results_patent
    FOREIGN KEY (patent_id) REFERENCES patents (patent_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT chk_search_result_score CHECK (similarity_score BETWEEN 0 AND 1),
  CONSTRAINT chk_search_result_rank CHECK (result_rank > 0)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS analyses (
  analysis_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  search_id BIGINT UNSIGNED NOT NULL,
  analysis_summary TEXT NOT NULL,
  conclusion TEXT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (analysis_id),
  UNIQUE KEY uq_analyses_search (search_id),
  CONSTRAINT fk_analyses_search
    FOREIGN KEY (search_id) REFERENCES searches (search_id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- Widen the original title field to accommodate longer invention titles.
ALTER TABLE inventions
  MODIFY title VARCHAR(200) NOT NULL;

CREATE OR REPLACE VIEW v_invention_catalog AS
SELECT
  i.invention_id,
  i.title,
  i.abstract,
  i.description,
  i.category,
  i.created_at,
  u.name AS created_by,
  GROUP_CONCAT(DISTINCT inv.name ORDER BY inv.name SEPARATOR ', ') AS inventors,
  COUNT(DISTINCT p.patent_id) AS patent_count
FROM inventions AS i
JOIN users AS u ON u.user_id = i.created_by
LEFT JOIN invention_inventors AS ii ON ii.invention_id = i.invention_id
LEFT JOIN inventors AS inv ON inv.inventor_id = ii.inventor_id
LEFT JOIN patent_applications AS pa ON pa.invention_id = i.invention_id
LEFT JOIN patents AS p ON p.application_id = pa.application_id
GROUP BY i.invention_id, i.title, i.abstract, i.description, i.category, i.created_at, u.name;

CREATE OR REPLACE VIEW v_application_pipeline AS
SELECT
  pa.application_id,
  i.invention_id,
  i.title AS invention_title,
  inv.name AS inventor_name,
  pa.application_number,
  pa.filing_date,
  pa.current_status,
  p.patent_number,
  p.publication_date
FROM patent_applications AS pa
JOIN inventions AS i ON i.invention_id = pa.invention_id
JOIN inventors AS inv ON inv.inventor_id = pa.inventor_id
LEFT JOIN patents AS p ON p.application_id = pa.application_id;

DROP TABLE IF EXISTS ddl_demo_scratch;

CREATE TABLE ddl_demo_scratch (
  scratch_id INT NOT NULL PRIMARY KEY
) ENGINE=InnoDB;

ALTER TABLE ddl_demo_scratch ADD COLUMN note VARCHAR(40) NULL;

DROP TABLE ddl_demo_scratch;
