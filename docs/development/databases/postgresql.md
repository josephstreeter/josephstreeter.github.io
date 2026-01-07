---
title: PostgreSQL - Advanced Open Source Database
description: Comprehensive guide to PostgreSQL, the powerful open-source relational database system with advanced features, ACID compliance, and robust performance capabilities
---

PostgreSQL is a powerful, open-source object-relational database system that uses and extends the SQL language combined with many features that safely store and scale the most complicated data workloads. With over 35 years of active development, PostgreSQL has earned a strong reputation for reliability, feature robustness, and performance.

## Overview

PostgreSQL (often referred to as "Postgres") is an advanced, enterprise-class relational database management system (RDBMS) that supports both SQL (relational) and JSON (non-relational) querying. It is highly extensible, ACID-compliant, and known for its standards compliance, advanced features like multi-version concurrency control (MVCC), point-in-time recovery, tablespaces, and sophisticated query optimization.

### Why PostgreSQL?

PostgreSQL excels in scenarios requiring:

- **Complex queries and analytics** - Advanced SQL features, window functions, CTEs
- **Data integrity** - Full ACID compliance, foreign keys, constraints
- **Extensibility** - Custom types, functions, operators, and extensions
- **Scalability** - Handles datasets from kilobytes to petabytes
- **Reliability** - Write-ahead logging, point-in-time recovery, replication
- **Standards compliance** - SQL:2016 compliant with many extensions

## Key Features

### ACID Compliance

PostgreSQL provides full ACID (Atomicity, Consistency, Isolation, Durability) guarantees:

- **Atomicity**: Transactions are all-or-nothing operations
- **Consistency**: Database remains in valid state after transactions
- **Isolation**: Concurrent transactions don't interfere with each other
- **Durability**: Committed data persists even after system failures

### Multi-Version Concurrency Control (MVCC)

MVCC allows:

- **Non-blocking reads** - Readers don't block writers, writers don't block readers
- **Consistent snapshots** - Queries see consistent data without locking
- **High concurrency** - Better performance under heavy load
- **Transaction isolation** - Multiple isolation levels supported

### Advanced Data Types

PostgreSQL supports extensive built-in types:

- **Numeric**: integer, bigint, decimal, numeric, real, double precision
- **Text**: varchar, char, text
- **Binary**: bytea
- **Date/Time**: date, time, timestamp, interval, timestamptz
- **Boolean**: boolean
- **Geometric**: point, line, circle, polygon, path
- **Network**: inet, cidr, macaddr, macaddr8
- **JSON**: json, jsonb (binary JSON with indexing)
- **Arrays**: Arrays of any built-in or user-defined type
- **UUID**: Universally unique identifiers
- **XML**: Native XML support
- **Range types**: int4range, tstzrange, daterange
- **Custom types**: User-defined composite and enumerated types

### Extensibility

PostgreSQL is designed to be extended:

- **Custom data types** - Define your own types
- **Custom functions** - Write functions in SQL, PL/pgSQL, Python, C, etc.
- **Custom operators** - Create domain-specific operators
- **Extensions** - Rich ecosystem of extensions (PostGIS, TimescaleDB, pgvector)
- **Foreign Data Wrappers** - Query external data sources
- **Procedural languages** - PL/pgSQL, PL/Python, PL/Perl, PL/Tcl, PL/R

## Installation

### Linux (Ubuntu/Debian)

```bash
# Add PostgreSQL APT repository
sudo apt install -y postgresql-common
sudo /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh

# Install PostgreSQL 16
sudo apt update
sudo apt install -y postgresql-16 postgresql-contrib-16

# Start PostgreSQL service
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Verify installation
psql --version
```

### Linux (RHEL/CentOS/Fedora)

```bash
# Install PostgreSQL repository
sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/F-39-x86_64/pgdg-fedora-repo-latest.noarch.rpm

# Install PostgreSQL 16
sudo dnf install -y postgresql16-server postgresql16-contrib

# Initialize database
sudo /usr/pgsql-16/bin/postgresql-16-setup initdb

# Start service
sudo systemctl start postgresql-16
sudo systemctl enable postgresql-16
```

### macOS

```bash
# Using Homebrew
brew install postgresql@16

# Start service
brew services start postgresql@16

# Or using Postgres.app (GUI)
# Download from https://postgresapp.com/
```

### Windows

```powershell
# Using Chocolatey
choco install postgresql16

# Or download installer from:
# https://www.postgresql.org/download/windows/

# PostgreSQL installer includes:
# - PostgreSQL Server
# - pgAdmin 4 (GUI management tool)
# - Command line tools
# - Stack Builder (extension manager)
```

### Docker

```bash
# Pull official image
docker pull postgres:16

# Run PostgreSQL container
docker run --name postgres-dev \
  -e POSTGRES_PASSWORD=mysecretpassword \
  -e POSTGRES_USER=myuser \
  -e POSTGRES_DB=mydb \
  -p 5432:5432 \
  -v postgres-data:/var/lib/postgresql/data \
  -d postgres:16

# Connect to container
docker exec -it postgres-dev psql -U myuser -d mydb
```

### Docker Compose

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:16
    container_name: postgres-dev
    environment:
      POSTGRES_USER: myuser
      POSTGRES_PASSWORD: mysecretpassword
      POSTGRES_DB: mydb
    ports:
      - "5432:5432"
    volumes:
      - postgres-data:/var/lib/postgresql/data
      - ./init-scripts:/docker-entrypoint-initdb.d
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U myuser"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  postgres-data:
```

## Initial Configuration

### Accessing PostgreSQL

```bash
# Switch to postgres user (Linux)
sudo -i -u postgres

# Connect to default database
psql

# Connect to specific database
psql -d database_name

# Connect as specific user
psql -U username -d database_name

# Connect to remote host
psql -h hostname -p 5432 -U username -d database_name
```

### Creating Users and Databases

```sql
-- Create new user
CREATE USER myuser WITH PASSWORD 'secure_password';

-- Create database
CREATE DATABASE mydb OWNER myuser;

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE mydb TO myuser;

-- Create user with specific permissions
CREATE USER readonly WITH PASSWORD 'password';
GRANT CONNECT ON DATABASE mydb TO readonly;
GRANT USAGE ON SCHEMA public TO readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly;

-- Create superuser
CREATE USER admin WITH SUPERUSER PASSWORD 'admin_password';
```

### Configuration Files

PostgreSQL uses three main configuration files:

#### postgresql.conf

Main configuration file for server settings:

```bash
# Find configuration file location
psql -c "SHOW config_file;"

# Common settings to modify:
# /var/lib/postgresql/data/postgresql.conf

listen_addresses = '*'                  # Listen on all interfaces
port = 5432                             # Port number
max_connections = 100                    # Maximum concurrent connections
shared_buffers = 256MB                   # Memory for caching data
effective_cache_size = 1GB               # OS cache estimate
work_mem = 4MB                          # Memory per query operation
maintenance_work_mem = 64MB              # Memory for maintenance operations
checkpoint_completion_target = 0.9       # Checkpoint spread
wal_buffers = 16MB                      # Write-ahead log buffer
default_statistics_target = 100          # Statistics collection
random_page_cost = 1.1                  # SSD optimization
effective_io_concurrency = 200           # Concurrent disk I/O
```

#### pg_hba.conf

Controls client authentication:

```text
# TYPE  DATABASE        USER            ADDRESS                 METHOD

# Local connections
local   all             all                                     peer

# IPv4 local connections
host    all             all             127.0.0.1/32            scram-sha-256

# IPv6 local connections
host    all             all             ::1/128                 scram-sha-256

# Allow connections from specific network
host    all             all             192.168.1.0/24          scram-sha-256

# Allow specific user from anywhere
host    mydb            myuser          0.0.0.0/0               scram-sha-256
```

Authentication methods:

- **trust** - No password required (development only)
- **peer** - Use OS username (local connections)
- **scram-sha-256** - Password authentication (recommended)
- **md5** - MD5 password authentication (legacy)
- **password** - Plain text password (not recommended)
- **cert** - SSL certificate authentication
- **ldap** - LDAP authentication

#### pg_ident.conf

Username mapping for external authentication:

```text
# MAPNAME       SYSTEM-USERNAME         PG-USERNAME
mymap           john                    postgres
mymap           root                    postgres
```

### Reloading Configuration

```bash
# Reload configuration without restart
sudo systemctl reload postgresql

# Or from within psql
SELECT pg_reload_conf();

# Full restart (required for some settings)
sudo systemctl restart postgresql
```

## Database Design

### Creating Tables

```sql
-- Simple table
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table with constraints
CREATE TABLE posts (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    title VARCHAR(200) NOT NULL,
    content TEXT,
    published BOOLEAN DEFAULT false,
    views INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Foreign key constraint
    CONSTRAINT fk_user
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    
    -- Check constraint
    CONSTRAINT check_views_positive
        CHECK (views >= 0)
);

-- Table with composite primary key
CREATE TABLE user_roles (
    user_id INTEGER,
    role_id INTEGER,
    granted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (user_id, role_id),
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (role_id) REFERENCES roles(id)
);
```

### Data Types Best Practices

```sql
-- Use appropriate numeric types
CREATE TABLE products (
    id BIGSERIAL PRIMARY KEY,           -- Auto-incrementing 64-bit integer
    sku VARCHAR(50) UNIQUE NOT NULL,    -- Variable length string
    name TEXT NOT NULL,                 -- Unlimited length text
    price NUMERIC(10, 2) NOT NULL,      -- Exact decimal (10 digits, 2 decimal places)
    quantity INTEGER DEFAULT 0,          -- 32-bit integer
    weight REAL,                        -- 32-bit floating point
    is_active BOOLEAN DEFAULT true,     -- Boolean
    metadata JSONB,                     -- Binary JSON (indexable)
    tags TEXT[],                        -- Array of text
    created_at TIMESTAMPTZ DEFAULT NOW() -- Timestamp with timezone
);

-- Use JSONB for semi-structured data
CREATE TABLE events (
    id BIGSERIAL PRIMARY KEY,
    event_type VARCHAR(50) NOT NULL,
    event_data JSONB NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- GIN index for JSONB queries
    INDEX idx_event_data ON events USING GIN (event_data)
);

-- Use arrays for multiple values
CREATE TABLE blog_posts (
    id SERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    tags TEXT[] DEFAULT '{}',
    categories INTEGER[] DEFAULT '{}'
);

-- Use range types for ranges
CREATE TABLE reservations (
    id SERIAL PRIMARY KEY,
    room_id INTEGER NOT NULL,
    time_range TSTZRANGE NOT NULL,
    
    -- Prevent overlapping reservations
    CONSTRAINT no_overlap
        EXCLUDE USING GIST (room_id WITH =, time_range WITH &&)
);
```

### Schemas

Schemas provide namespace organization:

```sql
-- Create schema
CREATE SCHEMA sales;
CREATE SCHEMA hr;

-- Create table in schema
CREATE TABLE sales.orders (
    id SERIAL PRIMARY KEY,
    customer_id INTEGER,
    order_date DATE DEFAULT CURRENT_DATE
);

-- Set search path
SET search_path TO sales, public;

-- Grant schema access
GRANT USAGE ON SCHEMA sales TO sales_user;
GRANT SELECT ON ALL TABLES IN SCHEMA sales TO sales_user;

-- Default privileges for future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA sales
    GRANT SELECT ON TABLES TO sales_user;
```

### Indexes

#### Index Types

```sql
-- B-tree index (default, most common)
CREATE INDEX idx_users_email ON users(email);

-- Partial index (index subset of rows)
CREATE INDEX idx_active_users ON users(username) 
WHERE is_active = true;

-- Composite index
CREATE INDEX idx_posts_user_date ON posts(user_id, created_at);

-- Unique index
CREATE UNIQUE INDEX idx_users_username ON users(username);

-- Expression index
CREATE INDEX idx_users_lower_email ON users(LOWER(email));

-- GIN index (for JSONB, arrays, full-text search)
CREATE INDEX idx_products_tags ON products USING GIN(tags);
CREATE INDEX idx_events_data ON events USING GIN(event_data);

-- GiST index (for geometric types, ranges)
CREATE INDEX idx_locations ON places USING GIST(location);

-- BRIN index (for very large tables with natural ordering)
CREATE INDEX idx_logs_created ON logs USING BRIN(created_at);

-- Hash index (equality comparisons only)
CREATE INDEX idx_sessions_token ON sessions USING HASH(session_token);
```

#### Index Strategies

```sql
-- Index for foreign keys
CREATE INDEX idx_posts_user_id ON posts(user_id);

-- Index for common WHERE clauses
CREATE INDEX idx_orders_status ON orders(status) 
WHERE status != 'completed';

-- Index for JOIN operations
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_order_items_product_id ON order_items(product_id);

-- Index for ORDER BY
CREATE INDEX idx_posts_created_desc ON posts(created_at DESC);

-- Covering index (includes extra columns)
CREATE INDEX idx_users_email_covering ON users(email) 
INCLUDE (username, created_at);
```

### Constraints

```sql
-- Primary key
CREATE TABLE departments (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL
);

-- Foreign key with actions
CREATE TABLE employees (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    department_id INTEGER,
    salary NUMERIC(10, 2),
    
    FOREIGN KEY (department_id) 
        REFERENCES departments(id)
        ON DELETE SET NULL
        ON UPDATE CASCADE,
    
    -- Check constraints
    CONSTRAINT check_salary_positive 
        CHECK (salary > 0),
    
    CONSTRAINT check_email_format 
        CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$')
);

-- Exclusion constraints
CREATE TABLE meetings (
    id SERIAL PRIMARY KEY,
    room_id INTEGER NOT NULL,
    time_slot TSTZRANGE NOT NULL,
    
    -- Prevent overlapping meetings in same room
    EXCLUDE USING GIST (
        room_id WITH =,
        time_slot WITH &&
    )
);
```

## Querying Data

### Basic Queries

```sql
-- Simple SELECT
SELECT id, username, email FROM users;

-- WHERE clause
SELECT * FROM users 
WHERE created_at > '2024-01-01' 
AND is_active = true;

-- ORDER BY
SELECT * FROM posts 
ORDER BY created_at DESC, views DESC
LIMIT 10;

-- DISTINCT
SELECT DISTINCT status FROM orders;

-- Aggregate functions
SELECT 
    COUNT(*) as total_users,
    COUNT(DISTINCT email) as unique_emails,
    MAX(created_at) as latest_signup,
    MIN(created_at) as earliest_signup
FROM users;

-- GROUP BY
SELECT 
    user_id,
    COUNT(*) as post_count,
    AVG(views) as avg_views,
    MAX(views) as max_views
FROM posts
GROUP BY user_id
HAVING COUNT(*) > 5
ORDER BY post_count DESC;
```

### Joins

```sql
-- INNER JOIN
SELECT 
    u.username,
    p.title,
    p.created_at
FROM users u
INNER JOIN posts p ON u.id = p.user_id
WHERE u.is_active = true;

-- LEFT JOIN
SELECT 
    u.username,
    COUNT(p.id) as post_count
FROM users u
LEFT JOIN posts p ON u.id = p.user_id
GROUP BY u.id, u.username
ORDER BY post_count DESC;

-- Multiple JOINs
SELECT 
    o.id as order_id,
    u.username,
    p.name as product_name,
    oi.quantity,
    oi.price
FROM orders o
INNER JOIN users u ON o.user_id = u.id
INNER JOIN order_items oi ON o.id = oi.order_id
INNER JOIN products p ON oi.product_id = p.id
WHERE o.status = 'completed';

-- CROSS JOIN
SELECT 
    d.name as department,
    l.name as location
FROM departments d
CROSS JOIN locations l;
```

### Subqueries

```sql
-- Subquery in WHERE
SELECT * FROM products
WHERE price > (SELECT AVG(price) FROM products);

-- Subquery in FROM
SELECT 
    category,
    avg_price,
    max_price
FROM (
    SELECT 
        category,
        AVG(price) as avg_price,
        MAX(price) as max_price
    FROM products
    GROUP BY category
) AS category_stats
WHERE avg_price > 100;

-- Correlated subquery
SELECT 
    p1.id,
    p1.name,
    p1.price,
    (SELECT AVG(price) 
     FROM products p2 
     WHERE p2.category = p1.category) as category_avg
FROM products p1;

-- EXISTS
SELECT * FROM users u
WHERE EXISTS (
    SELECT 1 FROM posts p 
    WHERE p.user_id = u.id AND p.published = true
);

-- IN with subquery
SELECT * FROM products
WHERE category_id IN (
    SELECT id FROM categories 
    WHERE is_active = true
);
```

### Common Table Expressions (CTEs)

```sql
-- Simple CTE
WITH active_users AS (
    SELECT id, username FROM users WHERE is_active = true
)
SELECT 
    au.username,
    COUNT(p.id) as post_count
FROM active_users au
LEFT JOIN posts p ON au.id = p.user_id
GROUP BY au.username;

-- Multiple CTEs
WITH 
    user_stats AS (
        SELECT 
            user_id,
            COUNT(*) as post_count,
            AVG(views) as avg_views
        FROM posts
        GROUP BY user_id
    ),
    top_users AS (
        SELECT user_id FROM user_stats 
        WHERE post_count > 10
    )
SELECT 
    u.username,
    us.post_count,
    us.avg_views
FROM users u
INNER JOIN user_stats us ON u.id = us.user_id
WHERE u.id IN (SELECT user_id FROM top_users);

-- Recursive CTE (organizational hierarchy)
WITH RECURSIVE employee_hierarchy AS (
    -- Base case: top-level employees
    SELECT id, name, manager_id, 1 as level
    FROM employees
    WHERE manager_id IS NULL
    
    UNION ALL
    
    -- Recursive case: employees with managers
    SELECT e.id, e.name, e.manager_id, eh.level + 1
    FROM employees e
    INNER JOIN employee_hierarchy eh ON e.manager_id = eh.id
)
SELECT * FROM employee_hierarchy ORDER BY level, name;
```

### Window Functions

```sql
-- ROW_NUMBER
SELECT 
    username,
    created_at,
    ROW_NUMBER() OVER (ORDER BY created_at) as signup_order
FROM users;

-- RANK and DENSE_RANK
SELECT 
    product_name,
    price,
    RANK() OVER (ORDER BY price DESC) as rank,
    DENSE_RANK() OVER (ORDER BY price DESC) as dense_rank
FROM products;

-- PARTITION BY
SELECT 
    category,
    product_name,
    price,
    AVG(price) OVER (PARTITION BY category) as category_avg,
    price - AVG(price) OVER (PARTITION BY category) as diff_from_avg
FROM products;

-- LAG and LEAD
SELECT 
    date,
    revenue,
    LAG(revenue, 1) OVER (ORDER BY date) as previous_day_revenue,
    LEAD(revenue, 1) OVER (ORDER BY date) as next_day_revenue,
    revenue - LAG(revenue, 1) OVER (ORDER BY date) as daily_change
FROM daily_sales;

-- Running totals
SELECT 
    date,
    amount,
    SUM(amount) OVER (ORDER BY date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as running_total
FROM transactions;

-- Moving average
SELECT 
    date,
    price,
    AVG(price) OVER (
        ORDER BY date 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) as moving_avg_7_days
FROM stock_prices;
```

### JSONB Queries

```sql
-- Query JSONB data
SELECT * FROM events
WHERE event_data->>'type' = 'purchase';

-- Access nested JSONB
SELECT 
    id,
    event_data->'user'->>'name' as user_name,
    event_data->'user'->>'email' as user_email
FROM events;

-- JSONB array elements
SELECT 
    id,
    jsonb_array_elements(event_data->'items') as item
FROM events;

-- JSONB operators
SELECT * FROM products
WHERE metadata @> '{"color": "red"}';  -- Contains

SELECT * FROM products
WHERE metadata ? 'warranty';  -- Key exists

SELECT * FROM products
WHERE metadata ?| array['warranty', 'guarantee'];  -- Any key exists

SELECT * FROM products
WHERE metadata ?& array['color', 'size'];  -- All keys exist

-- Update JSONB
UPDATE products
SET metadata = metadata || '{"last_updated": "2024-01-01"}'
WHERE id = 1;

-- Remove JSONB key
UPDATE products
SET metadata = metadata - 'old_field'
WHERE id = 1;
```

### Full-Text Search

```sql
-- Create tsvector column
ALTER TABLE articles ADD COLUMN search_vector tsvector;

-- Update search vector
UPDATE articles
SET search_vector = 
    setweight(to_tsvector('english', coalesce(title, '')), 'A') ||
    setweight(to_tsvector('english', coalesce(content, '')), 'B');

-- Create GIN index for search
CREATE INDEX idx_articles_search ON articles USING GIN(search_vector);

-- Search query
SELECT 
    id,
    title,
    ts_rank(search_vector, query) as rank
FROM articles, to_tsquery('english', 'postgresql & performance') as query
WHERE search_vector @@ query
ORDER BY rank DESC;

-- Trigger to automatically update search vector
CREATE TRIGGER articles_search_update
BEFORE INSERT OR UPDATE ON articles
FOR EACH ROW EXECUTE FUNCTION
tsvector_update_trigger(search_vector, 'pg_catalog.english', title, content);
```

## Transactions

### Basic Transactions

```sql
-- Simple transaction
BEGIN;

UPDATE accounts SET balance = balance - 100 WHERE id = 1;
UPDATE accounts SET balance = balance + 100 WHERE id = 2;

COMMIT;

-- Rollback on error
BEGIN;

UPDATE accounts SET balance = balance - 100 WHERE id = 1;
-- Something goes wrong
ROLLBACK;
```

### Isolation Levels

```sql
-- Read Uncommitted (not supported in PostgreSQL, behaves as Read Committed)
BEGIN TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

-- Read Committed (default)
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT * FROM accounts WHERE id = 1;
-- Another transaction can commit changes
SELECT * FROM accounts WHERE id = 1;  -- May see different data
COMMIT;

-- Repeatable Read
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT * FROM accounts WHERE id = 1;
-- Another transaction commits changes
SELECT * FROM accounts WHERE id = 1;  -- Sees same data as first SELECT
COMMIT;

-- Serializable (strictest)
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
-- Ensures complete isolation, may cause serialization failures
COMMIT;
```

### Savepoints

```sql
BEGIN;

INSERT INTO users (username, email) VALUES ('user1', 'user1@example.com');

SAVEPOINT sp1;

INSERT INTO posts (user_id, title) VALUES (1, 'First Post');

SAVEPOINT sp2;

INSERT INTO posts (user_id, title) VALUES (1, 'Second Post');

-- Rollback to specific savepoint
ROLLBACK TO SAVEPOINT sp2;

-- sp1 and first post still exist
COMMIT;
```

### Advisory Locks

```sql
-- Session-level advisory lock
SELECT pg_advisory_lock(12345);
-- Critical section
SELECT pg_advisory_unlock(12345);

-- Transaction-level advisory lock
BEGIN;
SELECT pg_advisory_xact_lock(12345);
-- Critical section
COMMIT;  -- Lock automatically released

-- Try lock (non-blocking)
SELECT pg_try_advisory_lock(12345);  -- Returns true if locked, false otherwise
```

## Performance Optimization

### EXPLAIN and EXPLAIN ANALYZE

```sql
-- Show query plan
EXPLAIN SELECT * FROM users WHERE email = 'user@example.com';

-- Show query plan with actual execution
EXPLAIN ANALYZE SELECT * FROM users WHERE email = 'user@example.com';

-- Detailed output
EXPLAIN (ANALYZE, BUFFERS, VERBOSE) 
SELECT * FROM posts p
INNER JOIN users u ON p.user_id = u.id
WHERE u.is_active = true;

-- Understanding EXPLAIN output:
-- - Seq Scan: Full table scan (slow for large tables)
-- - Index Scan: Using index (good)
-- - Index Only Scan: Using covering index (better)
-- - Bitmap Index Scan: Multiple index scans combined
-- - Nested Loop: Join method for small tables
-- - Hash Join: Join method for larger tables
-- - Merge Join: Join method for sorted data
```

### Query Optimization

```sql
-- Use indexes effectively
CREATE INDEX idx_orders_user_status ON orders(user_id, status);

-- Bad: Function on indexed column
SELECT * FROM users WHERE LOWER(email) = 'user@example.com';

-- Good: Expression index
CREATE INDEX idx_users_lower_email ON users(LOWER(email));
SELECT * FROM users WHERE LOWER(email) = 'user@example.com';

-- Use EXISTS instead of IN for large subqueries
-- Bad
SELECT * FROM users WHERE id IN (SELECT user_id FROM large_table);

-- Good
SELECT * FROM users u WHERE EXISTS (
    SELECT 1 FROM large_table lt WHERE lt.user_id = u.id
);

-- Avoid SELECT *
-- Bad
SELECT * FROM large_table WHERE id = 1;

-- Good
SELECT id, name, email FROM large_table WHERE id = 1;

-- Use LIMIT for pagination
SELECT * FROM posts 
ORDER BY created_at DESC 
LIMIT 20 OFFSET 0;

-- Better pagination with keyset
SELECT * FROM posts 
WHERE created_at < '2024-01-01 00:00:00'
ORDER BY created_at DESC 
LIMIT 20;
```

### Index Maintenance

```sql
-- Check index usage
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes
ORDER BY idx_scan ASC;

-- Find unused indexes
SELECT 
    schemaname,
    tablename,
    indexname
FROM pg_stat_user_indexes
WHERE idx_scan = 0 AND indexrelname NOT LIKE 'pg_toast%';

-- Reindex table
REINDEX TABLE users;

-- Reindex database
REINDEX DATABASE mydb;

-- Concurrent reindex (doesn't block writes)
REINDEX INDEX CONCURRENTLY idx_users_email;
```

### VACUUM and ANALYZE

```sql
-- Analyze table statistics (for query planner)
ANALYZE users;

-- Vacuum table (reclaim space)
VACUUM users;

-- Vacuum and analyze
VACUUM ANALYZE users;

-- Vacuum full (more aggressive, locks table)
VACUUM FULL users;

-- Check bloat
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size,
    n_dead_tup,
    n_live_tup,
    round(n_dead_tup * 100.0 / NULLIF(n_live_tup + n_dead_tup, 0), 2) as dead_pct
FROM pg_stat_user_tables
WHERE n_dead_tup > 0
ORDER BY n_dead_tup DESC;

-- Configure autovacuum
ALTER TABLE large_table SET (
    autovacuum_vacuum_scale_factor = 0.05,
    autovacuum_analyze_scale_factor = 0.02,
    autovacuum_vacuum_threshold = 1000
);
```

### Connection Pooling

```sql
-- Check active connections
SELECT 
    datname,
    COUNT(*) as connections,
    MAX(state) as state
FROM pg_stat_activity
GROUP BY datname;

-- Kill idle connections
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE state = 'idle' 
AND state_change < NOW() - INTERVAL '10 minutes'
AND datname = 'mydb';

-- Configure connection limits
ALTER DATABASE mydb CONNECTION LIMIT 100;
ALTER USER myuser CONNECTION LIMIT 10;
```

Use external connection poolers for better performance:

- **PgBouncer** - Lightweight connection pooler
- **Pgpool-II** - Connection pooler with load balancing
- **Connection pooling in application** - SQLAlchemy, Django, etc.

## Replication and High Availability

### Streaming Replication

#### Primary Server Configuration

```bash
# postgresql.conf
wal_level = replica
max_wal_senders = 10
max_replication_slots = 10
hot_standby = on
archive_mode = on
archive_command = 'cp %p /var/lib/postgresql/archive/%f'
```

```sql
-- Create replication user
CREATE USER replicator WITH REPLICATION PASSWORD 'repl_password';
```

```text
# pg_hba.conf
# Allow replication from standby server
host replication replicator 192.168.1.100/32 scram-sha-256
```

#### Standby Server Setup

```bash
# Stop PostgreSQL on standby
sudo systemctl stop postgresql

# Remove data directory
sudo rm -rf /var/lib/postgresql/16/main/*

# Create base backup from primary
sudo -u postgres pg_basebackup \
    -h primary-server-ip \
    -D /var/lib/postgresql/16/main \
    -U replicator \
    -P \
    -v \
    -R \
    -X stream \
    -C -S standby_slot

# Start standby
sudo systemctl start postgresql
```

```bash
# postgresql.conf on standby
hot_standby = on
```

#### Monitoring Replication

```sql
-- On primary: Check replication status
SELECT 
    client_addr,
    state,
    sent_lsn,
    write_lsn,
    flush_lsn,
    replay_lsn,
    sync_state
FROM pg_stat_replication;

-- Check replication lag
SELECT 
    client_addr,
    pg_wal_lsn_diff(sent_lsn, replay_lsn) as lag_bytes,
    extract(epoch from (now() - pg_last_xact_replay_timestamp())) as lag_seconds
FROM pg_stat_replication;

-- On standby: Check recovery status
SELECT pg_is_in_recovery();
SELECT pg_last_wal_receive_lsn();
SELECT pg_last_wal_replay_lsn();
```

### Logical Replication

```sql
-- On primary: Create publication
CREATE PUBLICATION my_publication FOR ALL TABLES;

-- Or specific tables
CREATE PUBLICATION sales_publication FOR TABLE orders, order_items;

-- On subscriber: Create subscription
CREATE SUBSCRIPTION my_subscription
    CONNECTION 'host=primary-server dbname=mydb user=replicator password=password'
    PUBLICATION my_publication;

-- Monitor logical replication
SELECT * FROM pg_stat_subscription;
SELECT * FROM pg_replication_slots;
```

### Failover Strategies

#### Manual Failover

```bash
# On standby: Promote to primary
sudo -u postgres pg_ctl promote -D /var/lib/postgresql/16/main

# Or use SQL
SELECT pg_promote();
```

#### Automatic Failover

Use tools like:

- **Patroni** - Template for high availability PostgreSQL
- **repmgr** - Replication manager
- **Pg Auto Failover** - Simple automated failover
- **Stolon** - PostgreSQL cloud-native HA

## Backup and Recovery

### Logical Backups

```bash
# Dump single database
pg_dump mydb > mydb_backup.sql

# Dump with custom format (allows parallel restore)
pg_dump -Fc mydb > mydb_backup.dump

# Dump specific tables
pg_dump -t users -t posts mydb > tables_backup.sql

# Dump all databases
pg_dumpall > all_databases.sql

# Dump only schema
pg_dump --schema-only mydb > schema.sql

# Dump only data
pg_dump --data-only mydb > data.sql

# Compressed backup
pg_dump mydb | gzip > mydb_backup.sql.gz
```

### Restore from Logical Backup

```bash
# Restore SQL file
psql mydb < mydb_backup.sql

# Restore custom format
pg_restore -d mydb mydb_backup.dump

# Restore with parallel jobs
pg_restore -j 4 -d mydb mydb_backup.dump

# Restore specific table
pg_restore -t users -d mydb mydb_backup.dump

# Restore to new database
createdb mydb_restored
pg_restore -d mydb_restored mydb_backup.dump
```

### Physical Backups

```bash
# Base backup (hot backup)
pg_basebackup -D /backup/base -Ft -z -P

# Base backup to directory
pg_basebackup -D /backup/base -P -v

# Incremental backup using WAL archiving
# Configure in postgresql.conf:
# archive_mode = on
# archive_command = 'test ! -f /archive/%f && cp %p /archive/%f'
```

### Point-In-Time Recovery (PITR)

```bash
# 1. Take base backup
pg_basebackup -D /backup/base -P -v

# 2. Archive WAL files continuously
# (configured in postgresql.conf)

# 3. Create recovery.signal file
touch /var/lib/postgresql/16/main/recovery.signal

# 4. Configure recovery in postgresql.conf or postgresql.auto.conf
restore_command = 'cp /archive/%f %p'
recovery_target_time = '2024-01-15 14:30:00'
# Or: recovery_target_xid = '12345'
# Or: recovery_target_name = 'my_savepoint'

# 5. Start PostgreSQL
sudo systemctl start postgresql
```

### Continuous Archiving

```bash
# postgresql.conf
archive_mode = on
archive_command = 'test ! -f /mnt/archive/%f && cp %p /mnt/archive/%f'
archive_timeout = 300  # Force switch every 5 minutes

# Or use WAL-G for cloud storage
archive_command = 'wal-g wal-push %p'
```

### Backup Tools

- **pgBackRest** - Advanced backup and restore tool
- **WAL-G** - Archival restoration tool for cloud storage
- **Barman** - Backup and Recovery Manager
- **pg_probackup** - Backup and recovery manager

## Security

### Authentication and Authorization

```sql
-- Create roles
CREATE ROLE app_user WITH LOGIN PASSWORD 'secure_password';
CREATE ROLE readonly;
CREATE ROLE readwrite;
CREATE ROLE admin WITH SUPERUSER LOGIN PASSWORD 'admin_password';

-- Grant role memberships
GRANT readonly TO app_user;
GRANT readwrite TO developer;

-- Grant database privileges
GRANT CONNECT ON DATABASE mydb TO app_user;
GRANT ALL PRIVILEGES ON DATABASE mydb TO admin;

-- Grant schema privileges
GRANT USAGE ON SCHEMA public TO app_user;
GRANT ALL ON SCHEMA public TO admin;

-- Grant table privileges
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO readwrite;

-- Grant sequence privileges (for SERIAL columns)
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO readwrite;

-- Set default privileges for future objects
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT ON TABLES TO readonly;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO readwrite;

-- Column-level security
GRANT SELECT (id, username, email) ON users TO app_user;

-- Row-level security (RLS)
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;

CREATE POLICY user_documents ON documents
    FOR ALL
    TO app_user
    USING (owner_id = current_user_id());

CREATE POLICY admin_all ON documents
    FOR ALL
    TO admin
    USING (true);
```

### SSL/TLS Configuration

```bash
# Generate self-signed certificate (development only)
openssl req -new -x509 -days 365 -nodes -text \
    -out server.crt \
    -keyout server.key \
    -subj "/CN=dbhost.example.com"

# Set permissions
chmod 600 server.key
chown postgres:postgres server.key server.crt

# Move to PostgreSQL data directory
mv server.key server.crt /var/lib/postgresql/16/main/

# Configure postgresql.conf
ssl = on
ssl_cert_file = 'server.crt'
ssl_key_file = 'server.key'
ssl_ciphers = 'HIGH:MEDIUM:+3DES:!aNULL'
ssl_prefer_server_ciphers = on
ssl_min_protocol_version = 'TLSv1.2'

# Require SSL in pg_hba.conf
hostssl all all 0.0.0.0/0 scram-sha-256
```

### Encryption

```sql
-- Install pgcrypto extension
CREATE EXTENSION pgcrypto;

-- Hash passwords
INSERT INTO users (username, password_hash)
VALUES ('user1', crypt('my_password', gen_salt('bf')));

-- Verify password
SELECT username FROM users
WHERE username = 'user1'
AND password_hash = crypt('my_password', password_hash);

-- Encrypt data
UPDATE sensitive_table
SET encrypted_field = pgp_sym_encrypt('sensitive data', 'encryption_key');

-- Decrypt data
SELECT pgp_sym_decrypt(encrypted_field, 'encryption_key') 
FROM sensitive_table;

-- Generate UUIDs
SELECT gen_random_uuid();
```

### Audit Logging

```bash
# postgresql.conf
logging_collector = on
log_destination = 'csvlog'
log_directory = 'log'
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
log_statement = 'all'  # none, ddl, mod, all
log_duration = on
log_connections = on
log_disconnections = on
log_line_prefix = '%m [%p] %u@%d '
```

```sql
-- Install pgaudit extension
CREATE EXTENSION pgaudit;

-- Configure auditing
ALTER SYSTEM SET pgaudit.log = 'all';
SELECT pg_reload_conf();

-- Audit specific objects
ALTER TABLE sensitive_table SET (pgaudit.log = 'all');
```

## Extensions

### Installing Extensions

```sql
-- List available extensions
SELECT * FROM pg_available_extensions ORDER BY name;

-- Install extension
CREATE EXTENSION IF NOT EXISTS extension_name;

-- List installed extensions
SELECT * FROM pg_extension;

-- Drop extension
DROP EXTENSION extension_name CASCADE;
```

### Popular Extensions

#### PostGIS - Geographic Objects

```sql
CREATE EXTENSION postgis;

-- Create table with geometry
CREATE TABLE locations (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    location GEOMETRY(Point, 4326)
);

-- Insert point
INSERT INTO locations (name, location)
VALUES ('Office', ST_SetSRID(ST_MakePoint(-122.4194, 37.7749), 4326));

-- Spatial queries
SELECT name, ST_AsText(location) FROM locations
WHERE ST_DWithin(
    location,
    ST_SetSRID(ST_MakePoint(-122.4, 37.7), 4326),
    1000  -- meters
);
```

#### pg_trgm - Fuzzy String Matching

```sql
CREATE EXTENSION pg_trgm;

-- Create index for similarity search
CREATE INDEX idx_users_name_trgm ON users USING GIN (name gin_trgm_ops);

-- Similarity search
SELECT name, similarity(name, 'john') as sim
FROM users
WHERE name % 'john'  -- % operator uses trigram similarity
ORDER BY sim DESC
LIMIT 10;

-- Fuzzy search
SELECT * FROM products
WHERE name ILIKE '%widget%' OR name % 'widget'
ORDER BY similarity(name, 'widget') DESC;
```

#### uuid-ossp - UUID Generation

```sql
CREATE EXTENSION "uuid-ossp";

-- Generate UUIDs
SELECT uuid_generate_v1();  -- Time-based
SELECT uuid_generate_v4();  -- Random

-- Use in table
CREATE TABLE documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL
);
```

#### hstore - Key-Value Store

```sql
CREATE EXTENSION hstore;

-- Create table with hstore
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name TEXT,
    attributes HSTORE
);

-- Insert data
INSERT INTO products (name, attributes)
VALUES ('Widget', 'color=>red, size=>large, weight=>5kg');

-- Query hstore
SELECT * FROM products
WHERE attributes->'color' = 'red';

SELECT * FROM products
WHERE attributes ? 'warranty';  -- Key exists

-- Create GIN index
CREATE INDEX idx_products_attributes ON products USING GIN(attributes);
```

#### TimescaleDB - Time-Series Data

```sql
CREATE EXTENSION timescaledb;

-- Create regular table
CREATE TABLE sensor_data (
    time TIMESTAMPTZ NOT NULL,
    sensor_id INTEGER,
    temperature DOUBLE PRECISION,
    humidity DOUBLE PRECISION
);

-- Convert to hypertable
SELECT create_hypertable('sensor_data', 'time');

-- Automatic partitioning and optimized queries
-- Insert data
INSERT INTO sensor_data VALUES
    (NOW(), 1, 22.5, 60.0),
    (NOW(), 2, 23.0, 58.5);

-- Time-based queries are optimized
SELECT 
    time_bucket('1 hour', time) AS hour,
    sensor_id,
    AVG(temperature) as avg_temp
FROM sensor_data
WHERE time > NOW() - INTERVAL '24 hours'
GROUP BY hour, sensor_id
ORDER BY hour DESC;
```

#### pgvector - Vector Similarity Search

```sql
CREATE EXTENSION vector;

-- Create table with vector column
CREATE TABLE embeddings (
    id SERIAL PRIMARY KEY,
    content TEXT,
    embedding VECTOR(1536)  -- OpenAI embedding dimension
);

-- Create index for similarity search
CREATE INDEX ON embeddings USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 100);

-- Insert embeddings
INSERT INTO embeddings (content, embedding)
VALUES ('Sample text', '[0.1, 0.2, 0.3, ...]');

-- Similarity search
SELECT content, embedding <=> '[0.1, 0.2, 0.3, ...]' AS distance
FROM embeddings
ORDER BY distance
LIMIT 10;
```

#### pg_stat_statements - Query Performance Tracking

```sql
CREATE EXTENSION pg_stat_statements;

-- Configure in postgresql.conf
shared_preload_libraries = 'pg_stat_statements'
pg_stat_statements.track = all

-- View slowest queries
SELECT 
    query,
    calls,
    total_exec_time,
    mean_exec_time,
    stddev_exec_time,
    rows
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 20;

-- Reset statistics
SELECT pg_stat_statements_reset();
```

## Python Integration

### psycopg2 - PostgreSQL Adapter

```python
import psycopg2
from psycopg2 import pool
from psycopg2.extras import RealDictCursor

# Basic connection
conn = psycopg2.connect(
    host="localhost",
    database="mydb",
    user="myuser",
    password="mypassword",
    port=5432
)

# Execute query
cursor = conn.cursor()
cursor.execute("SELECT * FROM users WHERE id = %s", (1,))
user = cursor.fetchone()

# Insert data
cursor.execute(
    "INSERT INTO users (username, email) VALUES (%s, %s)",
    ("john", "john@example.com")
)
conn.commit()

# Dictionary cursor
cursor = conn.cursor(cursor_factory=RealDictCursor)
cursor.execute("SELECT * FROM users")
users = cursor.fetchall()  # Returns list of dicts

# Close connections
cursor.close()
conn.close()

# Connection pooling
connection_pool = psycopg2.pool.SimpleConnectionPool(
    minconn=1,
    maxconn=10,
    host="localhost",
    database="mydb",
    user="myuser",
    password="mypassword"
)

# Get connection from pool
conn = connection_pool.getconn()
# Use connection
connection_pool.putconn(conn)
```

### psycopg3 - Modern PostgreSQL Adapter

```python
import psycopg

# Connection string
conninfo = "host=localhost dbname=mydb user=myuser password=mypassword"

# Context manager (auto-closes)
with psycopg.connect(conninfo) as conn:
    with conn.cursor() as cursor:
        cursor.execute("SELECT * FROM users WHERE id = %s", (1,))
        user = cursor.fetchone()

# Async support
import asyncio
import psycopg

async def query_users():
    async with await psycopg.AsyncConnection.connect(conninfo) as conn:
        async with conn.cursor() as cursor:
            await cursor.execute("SELECT * FROM users")
            users = await cursor.fetchall()
            return users

# Connection pool
from psycopg_pool import ConnectionPool

pool = ConnectionPool(conninfo, min_size=1, max_size=10)

with pool.connection() as conn:
    with conn.cursor() as cursor:
        cursor.execute("SELECT * FROM users")
```

### SQLAlchemy - ORM

```python
from sqlalchemy import create_engine, Column, Integer, String, DateTime, ForeignKey
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, relationship
from datetime import datetime

# Create engine
engine = create_engine(
    "postgresql://myuser:mypassword@localhost:5432/mydb",
    echo=True,  # Log SQL queries
    pool_size=10,
    max_overflow=20
)

Base = declarative_base()

# Define models
class User(Base):
    __tablename__ = 'users'
    
    id = Column(Integer, primary_key=True)
    username = Column(String(50), unique=True, nullable=False)
    email = Column(String(255), unique=True, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    posts = relationship('Post', back_populates='user')

class Post(Base):
    __tablename__ = 'posts'
    
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey('users.id'), nullable=False)
    title = Column(String(200), nullable=False)
    content = Column(String)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    user = relationship('User', back_populates='posts')

# Create tables
Base.metadata.create_all(engine)

# Create session
Session = sessionmaker(bind=engine)
session = Session()

# Insert
user = User(username='john', email='john@example.com')
session.add(user)
session.commit()

# Query
users = session.query(User).filter(User.username == 'john').all()

# Join query
results = session.query(User, Post).join(Post).filter(User.id == 1).all()

# Update
user = session.query(User).filter_by(username='john').first()
user.email = 'newemail@example.com'
session.commit()

# Delete
user = session.query(User).filter_by(username='john').first()
session.delete(user)
session.commit()

# Close session
session.close()
```

### Django ORM

```python
# settings.py
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'mydb',
        'USER': 'myuser',
        'PASSWORD': 'mypassword',
        'HOST': 'localhost',
        'PORT': '5432',
        'OPTIONS': {
            'connect_timeout': 10,
        },
    }
}

# models.py
from django.db import models

class User(models.Model):
    username = models.CharField(max_length=50, unique=True)
    email = models.EmailField(unique=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'users'
        indexes = [
            models.Index(fields=['username']),
            models.Index(fields=['email']),
        ]

class Post(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='posts')
    title = models.CharField(max_length=200)
    content = models.TextField()
    published = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'posts'
        ordering = ['-created_at']

# Usage
# Create
user = User.objects.create(username='john', email='john@example.com')

# Query
users = User.objects.filter(username='john')
user = User.objects.get(id=1)

# Update
User.objects.filter(id=1).update(email='newemail@example.com')

# Delete
User.objects.filter(id=1).delete()

# Join query
posts = Post.objects.select_related('user').filter(user__username='john')

# Aggregate
from django.db.models import Count, Avg
stats = User.objects.annotate(
    post_count=Count('posts'),
    avg_views=Avg('posts__views')
)
```

## Monitoring and Maintenance

### System Views

```sql
-- Database size
SELECT 
    datname,
    pg_size_pretty(pg_database_size(datname)) as size
FROM pg_database
ORDER BY pg_database_size(datname) DESC;

-- Table sizes
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as total_size,
    pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) as table_size,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename) - pg_relation_size(schemaname||'.'||tablename)) as index_size
FROM pg_tables
WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
LIMIT 20;

-- Active queries
SELECT 
    pid,
    usename,
    datname,
    state,
    query_start,
    state_change,
    wait_event_type,
    wait_event,
    query
FROM pg_stat_activity
WHERE state != 'idle'
ORDER BY query_start;

-- Long-running queries
SELECT 
    pid,
    now() - query_start as duration,
    usename,
    query
FROM pg_stat_activity
WHERE state != 'idle'
AND now() - query_start > interval '5 minutes'
ORDER BY duration DESC;

-- Blocking queries
SELECT 
    blocked_locks.pid AS blocked_pid,
    blocked_activity.usename AS blocked_user,
    blocking_locks.pid AS blocking_pid,
    blocking_activity.usename AS blocking_user,
    blocked_activity.query AS blocked_statement,
    blocking_activity.query AS blocking_statement
FROM pg_catalog.pg_locks blocked_locks
JOIN pg_catalog.pg_stat_activity blocked_activity ON blocked_activity.pid = blocked_locks.pid
JOIN pg_catalog.pg_locks blocking_locks 
    ON blocking_locks.locktype = blocked_locks.locktype
    AND blocking_locks.database IS NOT DISTINCT FROM blocked_locks.database
    AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
    AND blocking_locks.page IS NOT DISTINCT FROM blocked_locks.page
    AND blocking_locks.tuple IS NOT DISTINCT FROM blocked_locks.tuple
    AND blocking_locks.virtualxid IS NOT DISTINCT FROM blocked_locks.virtualxid
    AND blocking_locks.transactionid IS NOT DISTINCT FROM blocked_locks.transactionid
    AND blocking_locks.classid IS NOT DISTINCT FROM blocked_locks.classid
    AND blocking_locks.objid IS NOT DISTINCT FROM blocked_locks.objid
    AND blocking_locks.objsubid IS NOT DISTINCT FROM blocked_locks.objsubid
    AND blocking_locks.pid != blocked_locks.pid
JOIN pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
WHERE NOT blocked_locks.granted;

-- Cache hit ratio
SELECT 
    'cache hit rate' as metric,
    sum(heap_blks_hit) / (sum(heap_blks_hit) + sum(heap_blks_read)) * 100 as percentage
FROM pg_statio_user_tables;

-- Index usage
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch,
    pg_size_pretty(pg_relation_size(indexrelid)) as index_size
FROM pg_stat_user_indexes
ORDER BY idx_scan DESC;

-- Table statistics
SELECT 
    schemaname,
    tablename,
    seq_scan,
    seq_tup_read,
    idx_scan,
    idx_tup_fetch,
    n_tup_ins,
    n_tup_upd,
    n_tup_del,
    n_live_tup,
    n_dead_tup,
    last_vacuum,
    last_autovacuum,
    last_analyze,
    last_autoanalyze
FROM pg_stat_user_tables
ORDER BY seq_scan DESC;
```

### Monitoring Tools

- **pgAdmin** - Web-based administration tool
- **DBeaver** - Universal database tool
- **DataGrip** - JetBrains database IDE
- **pgMonitor** - Prometheus + Grafana monitoring
- **pgBadger** - Log analyzer
- **pg_stat_monitor** - Enhanced query performance monitoring
- **Datadog** - Full-stack monitoring
- **New Relic** - Application performance monitoring

## Best Practices

### Schema Design Best Practices

1. **Use appropriate data types** - Choose the smallest type that fits your data
2. **Add constraints** - Enforce data integrity at the database level
3. **Index foreign keys** - Critical for join performance
4. **Use SERIAL or BIGSERIAL** for auto-incrementing IDs
5. **Add NOT NULL where appropriate** - Makes query optimization easier
6. **Use TIMESTAMPTZ** - Always store timestamps with timezone
7. **Normalize appropriately** - Balance between normalization and query performance
8. **Use schemas** - Organize tables logically in namespaces

### Query Optimization Best Practices

1. **Use indexes wisely** - Index foreign keys and WHERE/ORDER BY columns
2. **Avoid SELECT *** - Only retrieve columns you need
3. **Use EXPLAIN ANALYZE** - Understand query performance
4. **Use JOINs instead of subqueries** - Often more efficient
5. **Filter early** - Apply WHERE clauses before JOINs when possible
6. **Use appropriate JOIN types** - INNER, LEFT, etc.
7. **Limit result sets** - Use LIMIT for pagination
8. **Use prepared statements** - Better performance and security

### Security Best Practices

1. **Use strong passwords** - Enforce password policies
2. **Enable SSL/TLS** - Encrypt client-server communication
3. **Principle of least privilege** - Grant minimum necessary permissions
4. **Use connection pooling** - Reduce connection overhead
5. **Regular security updates** - Keep PostgreSQL up to date
6. **Audit logging** - Track database access and changes
7. **Row-level security** - Implement fine-grained access control
8. **Encrypt sensitive data** - Use pgcrypto for encryption

### Maintenance

1. **Regular VACUUM** - Prevent table bloat
2. **Update statistics** - Run ANALYZE regularly
3. **Monitor disk space** - Ensure adequate storage
4. **Backup regularly** - Implement automated backups
5. **Test restores** - Verify backup integrity
6. **Monitor performance** - Track query performance over time
7. **Reindex periodically** - Maintain index health
8. **Plan for growth** - Monitor and plan capacity

### High Availability

1. **Use streaming replication** - Implement standby servers
2. **Configure automatic failover** - Use tools like Patroni
3. **Test failover procedures** - Regularly practice recovery
4. **Monitor replication lag** - Ensure standbys are up to date
5. **Use connection pooling** - Handle connection failures gracefully
6. **Implement load balancing** - Distribute read traffic
7. **Geographic distribution** - Consider multi-region deployment

## See Also

- [SQL Fundamentals](sql.md)
- [Database Design Best Practices](index.md)
- [Django with PostgreSQL](../python/web-development/django.md)
- [SQLAlchemy ORM](../python/orm/sqlalchemy.md)
- [Database Performance Tuning](performance-tuning.md)

## Additional Resources

### Official Documentation

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [PostgreSQL Wiki](https://wiki.postgresql.org/)
- [PostgreSQL Tutorials](https://www.postgresql.org/docs/current/tutorial.html)

### Community Resources

- [PostgreSQL Mailing Lists](https://www.postgresql.org/list/)
- [Planet PostgreSQL](https://planet.postgresql.org/) - Aggregated blogs
- [PgConf](https://www.pgconf.org/) - PostgreSQL conferences
- [PostgreSQL Slack](https://postgres-slack.herokuapp.com/)
- [Stack Overflow PostgreSQL Tag](https://stackoverflow.com/questions/tagged/postgresql)

### Tools and Extensions

- [pgAdmin](https://www.pgadmin.org/) - Administration platform
- [PostGIS](https://postgis.net/) - Spatial database extender
- [TimescaleDB](https://www.timescale.com/) - Time-series database
- [Citus](https://www.citusdata.com/) - Distributed PostgreSQL
- [pg_partman](https://github.com/pgpartman/pg_partman) - Partition management
- [pgBouncer](https://www.pgbouncer.org/) - Connection pooler

### Books

- "PostgreSQL: Up and Running" by Regina Obe and Leo Hsu
- "PostgreSQL High Performance" by Gregory Smith
- "Mastering PostgreSQL" by Hans-Jürgen Schönig
- "The Art of PostgreSQL" by Dimitri Fontaine
