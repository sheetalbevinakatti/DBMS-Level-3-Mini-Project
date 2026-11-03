USE patentpath_assignment;

INSERT INTO users (user_id, name, email, password_hash, role) VALUES
  (1, 'Aarav Sharma', 'aarav@example.com',
   'scrypt$93c0a266477b0a970d1b3e240b602123$6c0cb7e01ba6b82cb82b072a07b25ae3979f6625b3f3731188c22f1ec0ec7ae526ccc4d23f2f62e906b564cbda96ff3edf78f2fb5a5604a6b278c54bbbb541ca',
   'USER'),
  (2, 'Meera Nair', 'meera@example.com',
   'scrypt$44cb93673c83e30186ebabc2cfd12772$a2ed18c1c67b2410d18202bfff891dd3887271c3aca79a56ff2ca32c2664aec8201b92f262bb77bde258e4192e998b9171ebacd2ecded84c243041d08472947a',
   'USER'),
  (3, 'PatentPath Admin', 'admin@example.com',
   'scrypt$56fcad06cc865578e028342abd93c9bd$c71c8bfd9d2ca5e7786432c6e36630f075493bfc02770059a70146abcc7792dee07fad22bd0c418d5cf664eb473cd1e49b43595c7336f8d472a52781f9a13e32',
   'ADMIN')
ON DUPLICATE KEY UPDATE
  name = VALUES(name),
  email = VALUES(email),
  password_hash = VALUES(password_hash),
  role = VALUES(role);

INSERT INTO inventors
  (inventor_id, user_id, name, email, affiliation, contact_number, address)
VALUES
  (1, 1, 'Aarav Sharma', 'aarav@example.com', 'PatentPath Research Group', '+91-9000000001', 'Bengaluru, Karnataka'),
  (2, 2, 'Meera Nair', 'meera@example.com', 'Independent Researcher', '+91-9000000002', 'Bengaluru, Karnataka')
ON DUPLICATE KEY UPDATE
  user_id = VALUES(user_id),
  name = VALUES(name),
  email = VALUES(email),
  affiliation = VALUES(affiliation),
  contact_number = VALUES(contact_number),
  address = VALUES(address);

INSERT INTO inventions
  (invention_id, title, abstract, description, category, created_by)
VALUES
  (1, 'Smart Irrigation System',
   'An irrigation system that uses soil moisture readings to reduce unnecessary watering.',
   'The system monitors soil moisture using sensors and controls irrigation valves according to crop needs.',
   'Agriculture', 1),
  (2, 'Portable Air Quality Monitor',
   'A portable device that measures common air quality indicators and alerts its user.',
   'The device collects air quality readings and displays trends to help users identify exposure.',
   'Environment', 2),
  (3, 'Adaptive Battery Health Manager',
   'A charging controller that adjusts charging limits using battery temperature and usage patterns.',
   'The controller estimates battery condition and changes the charging profile to reduce avoidable wear.',
   'Energy', 1),
  (4, 'Low-Cost Water Leak Detector',
   'A network of acoustic sensors identifies probable leaks in building water pipes.',
   'The system compares acoustic readings across sensors and flags locations for inspection.',
   'Infrastructure', 2)
ON DUPLICATE KEY UPDATE
  title = VALUES(title),
  abstract = VALUES(abstract),
  description = VALUES(description),
  category = VALUES(category),
  created_by = VALUES(created_by);

INSERT INTO invention_inventors (invention_id, inventor_id) VALUES
  (1, 1), (1, 2), (2, 2), (3, 1), (4, 2)
ON DUPLICATE KEY UPDATE invention_id = VALUES(invention_id);

INSERT INTO patent_applications
  (application_id, application_number, invention_id, inventor_id, filing_date, current_status)
VALUES
  (1, 'PP-APP-2026-0001', 1, 1, '2026-08-12', 'APPROVED'),
  (2, 'PP-APP-2026-0002', 2, 2, '2026-09-03', 'UNDER_REVIEW'),
  (3, 'PP-APP-2026-0003', 3, 1, '2026-09-18', 'APPROVED'),
  (4, 'PP-APP-2026-0004', 4, 2, '2026-10-01', 'FILED')
ON DUPLICATE KEY UPDATE
  application_number = VALUES(application_number),
  invention_id = VALUES(invention_id),
  inventor_id = VALUES(inventor_id),
  filing_date = VALUES(filing_date),
  current_status = VALUES(current_status);

INSERT INTO patents
  (patent_id, application_id, patent_number, title, abstract, filing_date, publication_date)
VALUES
  (1, 1, 'PP-2026-0001', 'Smart Irrigation System',
   'A sensor-based irrigation control system that responds to soil moisture.',
   '2026-08-12', '2026-10-12'),
  (2, 3, 'PP-2026-0002', 'Adaptive Battery Health Manager',
   'A battery charging controller that adapts charging to estimated battery health.',
   '2026-09-18', '2026-10-20')
ON DUPLICATE KEY UPDATE
  application_id = VALUES(application_id),
  patent_number = VALUES(patent_number),
  title = VALUES(title),
  abstract = VALUES(abstract),
  filing_date = VALUES(filing_date),
  publication_date = VALUES(publication_date);

INSERT INTO searches (search_id, user_id, invention_id, query_text, search_method) VALUES
  (1, 1, 1, 'soil moisture based automatic irrigation', 'SEMANTIC'),
  (2, 2, 2, 'portable pollution measurement device', 'SEMANTIC'),
  (3, 1, 3, 'charging profile that extends battery life', 'SEMANTIC')
ON DUPLICATE KEY UPDATE
  user_id = VALUES(user_id),
  invention_id = VALUES(invention_id),
  query_text = VALUES(query_text),
  search_method = VALUES(search_method);

INSERT INTO search_results (search_id, patent_id, similarity_score, result_rank) VALUES
  (1, 1, 0.9234000, 1),
  (1, 2, 0.6112000, 2),
  (2, 1, 0.5841000, 1),
  (3, 2, 0.9473000, 1),
  (3, 1, 0.5025000, 2)
ON DUPLICATE KEY UPDATE
  similarity_score = VALUES(similarity_score),
  result_rank = VALUES(result_rank);

INSERT INTO analyses (analysis_id, search_id, analysis_summary, conclusion) VALUES
  (1, 1,
   'The closest indexed record concerns moisture-aware irrigation; the next result is less similar.',
   'Compare the sensor placement and valve-control claims before preparing a new application.'),
  (2, 2,
   'The available seed patents have limited overlap with portable air-quality monitoring.',
   'Broaden the search with sensor type, measured pollutants, and sampling method.'),
  (3, 3,
   'The closest indexed record concerns adaptive battery charging.',
   'Review the charging-control claims and document any distinct battery-health signals.')
ON DUPLICATE KEY UPDATE
  analysis_summary = VALUES(analysis_summary),
  conclusion = VALUES(conclusion);

-- Demo accounts (change these before any public deployment):
-- aarav@example.com / PatentPathDemo123!
-- meera@example.com / PatentPathDemo123!
-- admin@example.com / AdminDemo123!
