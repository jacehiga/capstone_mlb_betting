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

