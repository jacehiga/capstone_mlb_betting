-- Down Below is SQL that was used to Create and Populate the Needed Tables --

-- Creating json_mlb Table --
CREATE TABLE json_mlb (
  raw_json JSONB
);





-- Creating and Inserting Teams Table --
CREATE TABLE teams (
  team_id INT PRIMARY KEY,
  team_name TEXT
);

INSERT INTO teams (team_id, team_name) VALUES
(108, 'LAA'),  -- Los Angeles Angels
(109, 'ARI'),  -- Arizona Diamondbacks
(110, 'BAL'),  -- Baltimore Orioles
(111, 'BOS'),  -- Boston Red Sox
(112, 'CHC'),  -- Chicago Cubs
(113, 'CIN'),  -- Cincinnati Reds
(114, 'CLE'),  -- Cleveland Guardians
(115, 'COL'),  -- Colorado Rockies
(116, 'DET'),  -- Detroit Tigers
(117, 'HOU'),  -- Houston Astros
(118, 'KC'),   -- Kansas City Royals
(119, 'LAD'),  -- Los Angeles Dodgers
(120, 'WSH'),  -- Washington Nationals
(121, 'NYM'),  -- New York Mets
(133, 'OAK'),  -- Oakland Athletics
(134, 'PIT'),  -- Pittsburgh Pirates
(135, 'SD'),   -- San Diego Padres
(136, 'SEA'),  -- Seattle Mariners
(137, 'SF'),   -- San Francisco Giants
(138, 'STL'),  -- St. Louis Cardinals
(139, 'TB'),   -- Tampa Bay Rays
(140, 'TEX'),  -- Texas Rangers
(141, 'TOR'),  -- Toronto Blue Jays
(142, 'MIN'),  -- Minnesota Twins
(143, 'PHI'),  -- Philadelphia Phillies
(144, 'ATL'),  -- Atlanta Braves
(145, 'CWS'),  -- Chicago White Sox
(146, 'MIA'),  -- Miami Marlins
(147, 'NYY'),  -- New York Yankees
(158, 'MIL');  -- Milwaukee Brewers





CREATE TABLE games (
  game_id BIGINT PRIMARY KEY,
  date DATE,
  home_team_id BIGINT,
  home_score INT,
  away_team_id BIGINT,
  away_score INT
);
  
    
  


-- Batters Table --
CREATE TABLE batters (
    batter_id BIGINT,
    position TEXT,
    team_id BIGINT,
    PRIMARY KEY (batter_id, position, team_id)
);

 
 
 
 
 -- Pitchers Table -- 
CREATE TABLE pitchers (
    pitcher_id BIGINT,
    position TEXT CHECK (position IN ('SP', 'RP')),
    team_id BIGINT,
    PRIMARY KEY (pitcher_id, position, team_id)
);
  
  
  
    
  
  -- Batter Stats --
 CREATE TABLE batter_stats (
  game_id BIGINT,
  batter_id BIGINT,
  team_id BIGINT,
  side TEXT,
  position TEXT,
  ab INT,
  h INT,
  bb INT,
  r INT,
  rbi INT,
  so INT,
  double INT,
  triple INT,
  hr INT,
  sb INT,
  PRIMARY KEY (game_id, batter_id, team_id, position)
);



  
  
  -- Pitcher Stats --
CREATE TABLE pitcher_stats (
  game_id BIGINT,
  pitcher_id BIGINT,
  team_id BIGINT,
  side TEXT,
  type TEXT CHECK (type IN ('SP', 'RP')),
  ip FLOAT,
  h INT,
  r INT,
  er INT,
  bb INT,
  so INT,
  hr INT,
  pitches BIGINT,
  strikes BIGINT,
  era FLOAT,
  PRIMARY KEY (game_id, pitcher_id, team_id, type)
);







-- Insert Games --
INSERT INTO games (
  game_id,
  date,
  home_team_id,
  home_score,
  away_team_id,
  away_score
)
SELECT
  (raw_json->>'game_id')::BIGINT AS game_id,
  (raw_json->>'date')::DATE AS date,
  (raw_json->'home_team'->>'id')::BIGINT AS home_team_id,
  (raw_json->'final_score'->>(raw_json->'home_team'->>'id'))::INT AS home_score,
  (raw_json->'away_team'->>'id')::BIGINT AS away_team_id,
  (raw_json->'final_score'->>(raw_json->'away_team'->>'id'))::INT AS away_score
FROM json_mlb
ON CONFLICT (game_id) DO UPDATE
SET
  date = EXCLUDED.date,
  home_score = EXCLUDED.home_score,
  away_score = EXCLUDED.away_score;
  
  
 


-- Insert Away Batters --
WITH away_batters_expanded AS (
  SELECT
    (batter->>'personId')::BIGINT AS batter_id,
    batter->>'position' AS position,
    (raw_json->'away_team'->>'id')::BIGINT AS team_id
  FROM json_mlb,
       LATERAL jsonb_array_elements(raw_json->'away_batters') AS batter
  WHERE batter->>'personId' IS NOT NULL
    AND batter->>'personId' != '0'
    AND batter->>'position' IS NOT NULL
)
INSERT INTO batters (batter_id, position, team_id)
SELECT DISTINCT batter_id, position, team_id
FROM away_batters_expanded
ON CONFLICT (batter_id, position, team_id) DO UPDATE
SET team_id = EXCLUDED.team_id;



-- Insert Home Batters --
WITH home_batters_expanded AS (
  SELECT
    (batter->>'personId')::BIGINT AS batter_id,
    batter->>'position' AS position,
    (raw_json->'home_team'->>'id')::BIGINT AS team_id
  FROM json_mlb,
       LATERAL jsonb_array_elements(raw_json->'home_batters') AS batter
  WHERE batter->>'personId' IS NOT NULL
    AND batter->>'personId' != '0'
    AND batter->>'position' IS NOT NULL
)
INSERT INTO batters (batter_id, position, team_id)
SELECT DISTINCT batter_id, position, team_id
FROM home_batters_expanded
ON CONFLICT (batter_id, position, team_id) DO UPDATE
SET team_id = EXCLUDED.team_id;
  
 
 
 

-- Insert Away Pitchers --
WITH indexed_away_pitchers AS (
  SELECT
    CAST(raw_json->>'game_id' AS INT) AS game_id,
    (pitcher->>'personId')::BIGINT AS pitcher_id,
    CASE 
      WHEN row_number() OVER (PARTITION BY raw_json->>'game_id' ORDER BY ord) = 1 THEN 'SP'
      ELSE 'RP'
    END AS position,
    (raw_json->'away_team'->>'id')::BIGINT AS team_id
  FROM json_mlb,
       LATERAL jsonb_array_elements(raw_json->'away_pitchers') WITH ORDINALITY AS t(pitcher, ord)
  WHERE pitcher->>'personId' IS NOT NULL
    AND pitcher->>'personId' != '0'
)
INSERT INTO pitchers (pitcher_id, position, team_id)
SELECT DISTINCT pitcher_id, position, team_id
FROM indexed_away_pitchers
ON CONFLICT (pitcher_id, position, team_id) DO UPDATE
SET team_id = EXCLUDED.team_id;



-- Insert Home Pitchers --
WITH indexed_home_pitchers AS (
  SELECT
    CAST(raw_json->>'game_id' AS INT) AS game_id,
    (pitcher->>'personId')::BIGINT AS pitcher_id,
    CASE 
      WHEN row_number() OVER (PARTITION BY raw_json->>'game_id' ORDER BY ord) = 1 THEN 'SP'
      ELSE 'RP'
    END AS position,
    (raw_json->'home_team'->>'id')::BIGINT AS team_id
  FROM json_mlb,
       LATERAL jsonb_array_elements(raw_json->'home_pitchers') WITH ORDINALITY AS t(pitcher, ord)
  WHERE pitcher->>'personId' IS NOT NULL
    AND pitcher->>'personId' != '0'
)
INSERT INTO pitchers (pitcher_id, position, team_id)
SELECT DISTINCT pitcher_id, position, team_id
FROM indexed_home_pitchers
ON CONFLICT (pitcher_id, position, team_id) DO UPDATE
SET team_id = EXCLUDED.team_id;
  
  



-- Insert Away Batters Box Scores --
WITH away_box_scores AS (
  SELECT
    (raw_json->>'game_id')::BIGINT AS game_id,
    (batter->>'personId')::BIGINT AS batter_id,
    (raw_json->'away_team'->>'id')::BIGINT AS team_id,
    batter->>'position' AS position,
    'away' AS side,
    (batter->>'ab')::INT AS ab,
    (batter->>'h')::INT AS h,
    (batter->>'bb')::INT AS bb,
    (batter->>'r')::INT AS r,
    (batter->>'rbi')::INT AS rbi,
    (batter->>'k')::INT AS so,
    (batter->>'doubles')::INT AS double,
    (batter->>'triples')::INT AS triple,
    (batter->>'hr')::INT AS hr,
    (batter->>'sb')::INT AS sb
  FROM json_mlb,
       LATERAL jsonb_array_elements(raw_json->'away_batters') AS batter
  WHERE batter->>'personId' IS NOT NULL
    AND batter->>'personId' != '0'
    AND batter->>'position' IS NOT NULL
)
INSERT INTO batter_stats (
  game_id, batter_id, team_id, position, side,
  ab, h, bb, r, rbi, so, double, triple, hr, sb
)
SELECT * FROM away_box_scores
ON CONFLICT (game_id, batter_id, team_id, position) DO NOTHING;



-- Insert Home Batters Box Scores --
WITH home_box_scores AS (
  SELECT
    (raw_json->>'game_id')::BIGINT AS game_id,
    (batter->>'personId')::BIGINT AS batter_id,
    (raw_json->'home_team'->>'id')::BIGINT AS team_id,
    batter->>'position' AS position,
    'home' AS side,
    (batter->>'ab')::INT AS ab,
    (batter->>'h')::INT AS h,
    (batter->>'bb')::INT AS bb,
    (batter->>'r')::INT AS r,
    (batter->>'rbi')::INT AS rbi,
    (batter->>'k')::INT AS so,
    (batter->>'doubles')::INT AS double,
    (batter->>'triples')::INT AS triple,
    (batter->>'hr')::INT AS hr,
    (batter->>'sb')::INT AS sb
  FROM json_mlb,
       LATERAL jsonb_array_elements(raw_json->'home_batters') AS batter
  WHERE batter->>'personId' IS NOT NULL
    AND batter->>'personId' != '0'
    AND batter->>'position' IS NOT NULL
)
INSERT INTO batter_stats (
  game_id, batter_id, team_id, position, side,
  ab, h, bb, r, rbi, so, double, triple, hr, sb
)
SELECT * FROM home_box_scores
ON CONFLICT (game_id, batter_id, team_id, position) DO NOTHING;





-- Insert Away Pitchers Box Scores --
WITH indexed_away_pitchers AS (
  SELECT
    (raw_json->>'game_id')::BIGINT AS game_id,
    (pitcher->>'personId')::BIGINT AS pitcher_id,
    (raw_json->'away_team'->>'id')::BIGINT AS team_id,
    'away' AS side,
    CASE 
      WHEN row_number() OVER (PARTITION BY raw_json->>'game_id' ORDER BY ord) = 1 THEN 'SP'
      ELSE 'RP'
    END AS type,
    (pitcher->>'ip')::FLOAT AS ip,
    (pitcher->>'h')::INT AS h,
    (pitcher->>'r')::INT AS r,
    (pitcher->>'er')::INT AS er,
    (pitcher->>'bb')::INT AS bb,
    (pitcher->>'k')::INT AS so,
    (pitcher->>'hr')::INT AS hr,
    (pitcher->>'p')::BIGINT AS pitches,
    (pitcher->>'s')::BIGINT AS strikes,
    (pitcher->>'era')::FLOAT AS era
  FROM json_mlb,
       LATERAL jsonb_array_elements(raw_json->'away_pitchers') WITH ORDINALITY AS t(pitcher, ord)
  WHERE pitcher->>'personId' IS NOT NULL AND pitcher->>'personId' != '0'
)
INSERT INTO pitcher_stats (
  game_id, pitcher_id, team_id, side, type, ip, h, r, er, bb, so, hr, pitches, strikes, era
)
SELECT * FROM indexed_away_pitchers
ON CONFLICT DO NOTHING;



-- Insert Home Pitchers Box Scores --
WITH indexed_home_pitchers AS (
  SELECT
    (raw_json->>'game_id')::BIGINT AS game_id,
    (pitcher->>'personId')::BIGINT AS pitcher_id,
    (raw_json->'home_team'->>'id')::BIGINT AS team_id,
    'home' AS side,
    CASE 
      WHEN row_number() OVER (PARTITION BY raw_json->>'game_id' ORDER BY ord) = 1 THEN 'SP'
      ELSE 'RP'
    END AS type,
    (pitcher->>'ip')::FLOAT AS ip,
    (pitcher->>'h')::INT AS h,
    (pitcher->>'r')::INT AS r,
    (pitcher->>'er')::INT AS er,
    (pitcher->>'bb')::INT AS bb,
    (pitcher->>'k')::INT AS so,
    (pitcher->>'hr')::INT AS hr,
    (pitcher->>'p')::BIGINT AS pitches,
    (pitcher->>'s')::BIGINT AS strikes,
    (pitcher->>'era')::FLOAT AS era
  FROM json_mlb,
       LATERAL jsonb_array_elements(raw_json->'home_pitchers') WITH ORDINALITY AS t(pitcher, ord)
  WHERE pitcher->>'personId' IS NOT NULL AND pitcher->>'personId' != '0'
)
INSERT INTO pitcher_stats (
  game_id, pitcher_id, team_id, side, type, ip, h, r, er, bb, so, hr, pitches, strikes, era
)
SELECT * FROM indexed_home_pitchers
ON CONFLICT DO NOTHING;
