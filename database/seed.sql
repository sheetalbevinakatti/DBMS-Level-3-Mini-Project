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

INSERT INTO inventions (title, abstract, description, category, created_by)
SELECT
  'Solar-Powered Crop Storage Monitor',
  'A solar-powered monitoring unit tracks temperature and humidity in small crop-storage facilities and warns operators when produce may be at risk.',
  'The unit combines low-power temperature and humidity sensors with a solar-charged battery. Local alerts help farmers respond to storage conditions without requiring continuous grid power.',
  'Agriculture',
  1
FROM DUAL
WHERE NOT EXISTS (
  SELECT 1 FROM inventions
  WHERE title = 'Solar-Powered Crop Storage Monitor' AND category = 'Agriculture'
);

INSERT INTO inventions (title, abstract, description, category, created_by)
SELECT
  'Wearable Fall Detection and Alert Device',
  'A wearable device analyzes motion-sensor readings to detect likely falls and notify a designated contact.',
  'The device evaluates acceleration and orientation patterns, then provides a user-cancelable alert before sending a notification. It is designed as an assistive alert, not a medical diagnostic.',
  'Healthcare',
  2
FROM DUAL
WHERE NOT EXISTS (
  SELECT 1 FROM inventions
  WHERE title = 'Wearable Fall Detection and Alert Device' AND category = 'Healthcare'
);

INSERT INTO inventions (title, abstract, description, category, created_by)
SELECT
  'Adaptive Traffic Signal Coordinator',
  'A traffic-control system adjusts signal timing using vehicle queue estimates from connected roadside sensors.',
  'The coordinator combines live lane-level counts with configurable timing limits to reduce unnecessary waits while preserving pedestrian crossing intervals.',
  'Transportation',
  1
FROM DUAL
WHERE NOT EXISTS (
  SELECT 1 FROM inventions
  WHERE title = 'Adaptive Traffic Signal Coordinator' AND category = 'Transportation'
);

INSERT INTO inventions (title, abstract, description, category, created_by)
SELECT
  'Greywater Reuse Quality Controller',
  'A household controller monitors basic greywater conditions and routes suitable water to non-potable reuse.',
  'Sensor readings and configurable thresholds control diverter valves between a treatment stage, a reuse tank, and a safe drain path. The system keeps potable plumbing separate.',
  'Water Management',
  2
FROM DUAL
WHERE NOT EXISTS (
  SELECT 1 FROM inventions
  WHERE title = 'Greywater Reuse Quality Controller' AND category = 'Water Management'
);

INSERT INTO inventions (title, abstract, description, category, created_by)
SELECT
  'Community Flood Early Warning Network',
  'A neighborhood sensor network combines local water-level readings to warn residents when flood conditions may be developing.',
  'Low-power riverbank and drainage sensors report water levels to a local gateway. The gateway applies configurable thresholds and relays alerts to community operators when readings rise.',
  'Disaster Resilience',
  2
FROM DUAL
WHERE NOT EXISTS (
  SELECT 1 FROM inventions
  WHERE title = 'Community Flood Early Warning Network' AND category = 'Disaster Resilience'
);

INSERT INTO inventions (title, abstract, description, category, created_by)
SELECT
  'Adaptive Assistive Reading Display',
  'An electronic reading display adjusts text spacing and contrast using reader-selected accessibility preferences.',
  'The display stores per-reader presentation settings and applies them to imported text. Controls support adjustable font size, line spacing, and contrast without changing the source document.',
  'Accessibility',
  1
FROM DUAL
WHERE NOT EXISTS (
  SELECT 1 FROM inventions
  WHERE title = 'Adaptive Assistive Reading Display' AND category = 'Accessibility'
);

INSERT INTO inventions (title, abstract, description, category, created_by)
SELECT
  'Predictive Industrial Vibration Monitor',
  'A machine-monitoring unit tracks equipment vibration trends and flags readings that may need maintenance review.',
  'The unit samples vibration at configured intervals, compares the measurements with an equipment-specific baseline, and records trend alerts for maintenance teams.',
  'Manufacturing',
  2
FROM DUAL
WHERE NOT EXISTS (
  SELECT 1 FROM inventions
  WHERE title = 'Predictive Industrial Vibration Monitor' AND category = 'Manufacturing'
);

INSERT INTO inventions (title, abstract, description, category, created_by)
SELECT
  'Community Solar Load Balancer',
  'A local energy controller schedules flexible loads using community solar generation and shared battery availability.',
  'The controller reads generation and storage measurements, then schedules configured noncritical loads within operator-defined limits to better align local demand with available renewable power.',
  'Energy',
  1
FROM DUAL
WHERE NOT EXISTS (
  SELECT 1 FROM inventions
  WHERE title = 'Community Solar Load Balancer' AND category = 'Energy'
);

INSERT INTO invention_inventors (invention_id, inventor_id) VALUES
  (1, 1), (1, 2), (2, 2), (3, 1), (4, 2)
ON DUPLICATE KEY UPDATE invention_id = VALUES(invention_id);

INSERT INTO invention_inventors (invention_id, inventor_id)
SELECT i.invention_id, 1
FROM inventions AS i
WHERE i.title = 'Solar-Powered Crop Storage Monitor' AND i.category = 'Agriculture'
ON DUPLICATE KEY UPDATE invention_id = VALUES(invention_id);

INSERT INTO invention_inventors (invention_id, inventor_id)
SELECT i.invention_id, 2
FROM inventions AS i
WHERE i.title = 'Wearable Fall Detection and Alert Device' AND i.category = 'Healthcare'
ON DUPLICATE KEY UPDATE invention_id = VALUES(invention_id);

INSERT INTO invention_inventors (invention_id, inventor_id)
SELECT i.invention_id, 1
FROM inventions AS i
WHERE i.title = 'Adaptive Traffic Signal Coordinator' AND i.category = 'Transportation'
ON DUPLICATE KEY UPDATE invention_id = VALUES(invention_id);

INSERT INTO invention_inventors (invention_id, inventor_id)
SELECT i.invention_id, 2
FROM inventions AS i
WHERE i.title = 'Greywater Reuse Quality Controller' AND i.category = 'Water Management'
ON DUPLICATE KEY UPDATE invention_id = VALUES(invention_id);

INSERT INTO invention_inventors (invention_id, inventor_id)
SELECT i.invention_id, 2
FROM inventions AS i
WHERE i.title = 'Community Flood Early Warning Network' AND i.category = 'Disaster Resilience'
ON DUPLICATE KEY UPDATE invention_id = VALUES(invention_id);

INSERT INTO invention_inventors (invention_id, inventor_id)
SELECT i.invention_id, 1
FROM inventions AS i
WHERE i.title = 'Adaptive Assistive Reading Display' AND i.category = 'Accessibility'
ON DUPLICATE KEY UPDATE invention_id = VALUES(invention_id);

INSERT INTO invention_inventors (invention_id, inventor_id)
SELECT i.invention_id, 2
FROM inventions AS i
WHERE i.title = 'Predictive Industrial Vibration Monitor' AND i.category = 'Manufacturing'
ON DUPLICATE KEY UPDATE invention_id = VALUES(invention_id);

INSERT INTO invention_inventors (invention_id, inventor_id)
SELECT i.invention_id, 1
FROM inventions AS i
WHERE i.title = 'Community Solar Load Balancer' AND i.category = 'Energy'
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

INSERT INTO patent_applications
  (application_number, invention_id, inventor_id, filing_date, current_status)
VALUES
  ('PP-APP-2026-0005',
   (SELECT invention_id FROM inventions WHERE title = 'Solar-Powered Crop Storage Monitor' AND category = 'Agriculture' ORDER BY invention_id LIMIT 1),
   1, '2026-10-10', 'APPROVED'),
  ('PP-APP-2026-0006',
   (SELECT invention_id FROM inventions WHERE title = 'Wearable Fall Detection and Alert Device' AND category = 'Healthcare' ORDER BY invention_id LIMIT 1),
   2, '2026-10-14', 'UNDER_REVIEW'),
  ('PP-APP-2026-0007',
   (SELECT invention_id FROM inventions WHERE title = 'Adaptive Traffic Signal Coordinator' AND category = 'Transportation' ORDER BY invention_id LIMIT 1),
   1, '2026-10-18', 'FILED'),
  ('PP-APP-2026-0008',
   (SELECT invention_id FROM inventions WHERE title = 'Greywater Reuse Quality Controller' AND category = 'Water Management' ORDER BY invention_id LIMIT 1),
   2, '2026-10-22', 'APPROVED')
ON DUPLICATE KEY UPDATE
  invention_id = VALUES(invention_id),
  inventor_id = VALUES(inventor_id),
  filing_date = VALUES(filing_date),
  current_status = VALUES(current_status);

INSERT INTO patent_applications
  (application_number, invention_id, inventor_id, filing_date, current_status)
VALUES
  ('PP-APP-2026-0009',
   (SELECT invention_id FROM inventions WHERE title = 'Community Flood Early Warning Network' AND category = 'Disaster Resilience' ORDER BY invention_id LIMIT 1),
   2, '2026-10-25', 'APPROVED'),
  ('PP-APP-2026-0010',
   (SELECT invention_id FROM inventions WHERE title = 'Adaptive Assistive Reading Display' AND category = 'Accessibility' ORDER BY invention_id LIMIT 1),
   1, '2026-10-28', 'UNDER_REVIEW'),
  ('PP-APP-2026-0011',
   (SELECT invention_id FROM inventions WHERE title = 'Predictive Industrial Vibration Monitor' AND category = 'Manufacturing' ORDER BY invention_id LIMIT 1),
   2, '2026-11-01', 'FILED'),
  ('PP-APP-2026-0012',
   (SELECT invention_id FROM inventions WHERE title = 'Community Solar Load Balancer' AND category = 'Energy' ORDER BY invention_id LIMIT 1),
   1, '2026-11-03', 'DRAFT')
ON DUPLICATE KEY UPDATE
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

INSERT INTO patents
  (application_id, patent_number, title, abstract, filing_date, publication_date)
VALUES
  ((SELECT application_id FROM patent_applications WHERE application_number = 'PP-APP-2026-0005'),
   'PP-2026-0003', 'Solar-Powered Crop Storage Monitor',
   'A low-power sensor unit monitors temperature and humidity in crop storage.',
   '2026-10-10', '2026-11-01'),
  ((SELECT application_id FROM patent_applications WHERE application_number = 'PP-APP-2026-0008'),
   'PP-2026-0004', 'Greywater Reuse Quality Controller',
   'A sensor-guided controller routes suitable greywater to non-potable reuse.',
   '2026-10-22', NULL)
ON DUPLICATE KEY UPDATE
  application_id = VALUES(application_id),
  title = VALUES(title),
  abstract = VALUES(abstract),
  filing_date = VALUES(filing_date),
  publication_date = VALUES(publication_date);

INSERT INTO patents
  (application_id, patent_number, title, abstract, filing_date, publication_date)
VALUES
  ((SELECT application_id FROM patent_applications WHERE application_number = 'PP-APP-2026-0009'),
   'PP-2026-0005', 'Community Flood Early Warning Network',
   'A distributed sensor network reports local water levels to support flood alerts.',
   '2026-10-25', '2026-11-04')
ON DUPLICATE KEY UPDATE
  application_id = VALUES(application_id),
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
