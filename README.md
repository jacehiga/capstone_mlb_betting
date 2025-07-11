# MLB Betting Data Acquisition

This is for my capstone project, and highlights the data acquisition I conducted for my MLB Betting analysis. I wrote two scrapers, one that uses selenium to scrape the mlb.com official website and the other that scrapes statsapi. It is an ongoing project that will be fully completed by August 17th.
---

## Connection to Tables
Here is some connection info if one wanted to query tables through SQL using the tables I created.

```sql
-- Enable the postgres_fdw extension (if not already available)
CREATE EXTENSION postgres_fdw;

-- 1. Create foreign server
CREATE SERVER mlb_scraper_remote2
FOREIGN DATA WRAPPER postgres_fdw
OPTIONS (
  host 'switchyard.proxy.rlwy.net',
  port '42251',
  dbname 'railway'
);

-- 2. Create user mapping
CREATE USER MAPPING FOR CURRENT_USER
SERVER mlb_scraper_remote2
OPTIONS (
  user 'postgres',
  password 'onfxNlZFioFScuucmNhZKHhzPggcMfvd'
);

-- 3. Create local schema 
CREATE SCHEMA IF NOT EXISTS mlb_data;

-- 4. Import schema
IMPORT FOREIGN SCHEMA public
FROM SERVER mlb_scraper_remote2
INTO mlb_data;
```
