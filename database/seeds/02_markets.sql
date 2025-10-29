-- =============================================
-- Fichier: database/seeds/02_markets.sql
-- Description: Types de marchés de paris par sport
-- =============================================

-- FOOTBALL - Marchés principaux
INSERT INTO MarketNames (sport_id, code, name, created_at) VALUES
  ((SELECT id FROM Sports WHERE code='FOOT'), '1X2', '1X2 (Match Winner)', NOW()),
  ((SELECT id FROM Sports WHERE code='FOOT'), '1X2H1', '1X2 - 1st Half', NOW()),
  ((SELECT id FROM Sports WHERE code='FOOT'), '1X2H2', '1X2 - 2nd Half', NOW()),
  ((SELECT id FROM Sports WHERE code='FOOT'), 'BTTS', 'Both Teams To Score', NOW()),
  ((SELECT id FROM Sports WHERE code='FOOT'), 'DC', 'Double Chance', NOW()),
  ((SELECT id FROM Sports WHERE code='FOOT'), 'DNB', 'Draw No Bet', NOW()),
  ((SELECT id FROM Sports WHERE code='FOOT'), 'OU', 'Over/Under Goals', NOW()),
  ((SELECT id FROM Sports WHERE code='FOOT'), 'OU1H', 'Over/Under - 1st Half', NOW()),
  ((SELECT id FROM Sports WHERE code='FOOT'), 'FTS', 'First Team to Score', NOW()),
  ((SELECT id FROM Sports WHERE code='FOOT'), 'LTS', 'Last Team to Score', NOW()),
  ((SELECT id FROM Sports WHERE code='FOOT'), 'HC', 'Handicap', NOW()),
  ((SELECT id FROM Sports WHERE code='FOOT'), 'HTFT', 'Half Time / Full Time', NOW())
ON DUPLICATE KEY UPDATE name = VALUES(name);

-- BASKETBALL - Marchés principaux
INSERT INTO MarketNames (sport_id, code, name, created_at) VALUES
  ((SELECT id FROM Sports WHERE code='BASK'), '1X2', 'Match Winner', NOW()),
  ((SELECT id FROM Sports WHERE code='BASK'), 'OU', 'Over/Under Points', NOW()),
  ((SELECT id FROM Sports WHERE code='BASK'), 'HC', 'Handicap', NOW()),
  ((SELECT id FROM Sports WHERE code='BASK'), 'OU1Q', 'Over/Under - 1st Quarter', NOW()),
  ((SELECT id FROM Sports WHERE code='BASK'), 'OU1H', 'Over/Under - 1st Half', NOW())
ON DUPLICATE KEY UPDATE name = VALUES(name);

-- TENNIS - Marchés principaux
INSERT INTO MarketNames (sport_id, code, name, created_at) VALUES
  ((SELECT id FROM Sports WHERE code='TENN'), '1X2', 'Match Winner', NOW()),
  ((SELECT id FROM Sports WHERE code='TENN'), 'SET', 'Set Winner', NOW()),
  ((SELECT id FROM Sports WHERE code='TENN'), 'OU', 'Over/Under Games', NOW()),
  ((SELECT id FROM Sports WHERE code='TENN'), 'HC', 'Handicap Games', NOW())
ON DUPLICATE KEY UPDATE name = VALUES(name);

-- RUGBY - Marchés principaux
INSERT INTO MarketNames (sport_id, code, name, created_at) VALUES
  ((SELECT id FROM Sports WHERE code='RUGB'), '1X2', '1X2 (Match Winner)', NOW()),
  ((SELECT id FROM Sports WHERE code='RUGB'), 'OU', 'Over/Under Points', NOW()),
  ((SELECT id FROM Sports WHERE code='RUGB'), 'HC', 'Handicap', NOW()),
  ((SELECT id FROM Sports WHERE code='RUGB'), 'OU1H', 'Over/Under - 1st Half', NOW())
ON DUPLICATE KEY UPDATE name = VALUES(name);

SELECT 'Markets inserted successfully!' as Status;
SELECT COUNT(*) as Total FROM MarketNames;