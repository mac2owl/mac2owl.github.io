## Postgres

### Tools and cheatsheet

Online playground: [DB Fiddle](https://www.db-fiddle.com/)  
GUI tool: TablePlus  
[Postgres.app (Mac)](https://postgresapp.com/)  
[Cheatsheet](https://www.postgresqltutorial.com/postgresql-cheat-sheet/)

### Enable uuid generation

```SQL
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
```

### Create table with foreign key constraints/references

```SQL
CREATE TABLE departments (
	id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
	name VARCHAR(255) NOT NULL,
	created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
	updated_at TIMESTAMP WITH TIME ZONE DEFAULT NULL
);

CREATE TABLE employees (
	id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
	email VARCHAR(255) UNIQUE NOT NULL,
	first_name VARCHAR(255) NOT NULL,
	last_name VARCHAR(255) NOT NULL,
	department_id uuid NOT NULL,
	created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
	updated_at TIMESTAMP WITH TIME ZONE DEFAULT NULL,
	FOREIGN KEY (department_id) REFERENCES departments(id) ON DELETE CASCADE
);
```

or

```SQL
CREATE TABLE departments (
	id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
	name VARCHAR(255) NOT NULL,
	created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
	updated_at TIMESTAMP WITH TIME ZONE DEFAULT NULL
);

CREATE TABLE employees (
	id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
	email VARCHAR(255) UNIQUE NOT NULL,
	first_name VARCHAR(255) NOT NULL,
	last_name VARCHAR(255) NOT NULL,
	department_id uuid NOT NULL REFERENCES departments(id) ON DELETE CASCADE,
	created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
	updated_at TIMESTAMP WITH TIME ZONE DEFAULT NULL
);
```

### Insert values to table

```SQL
INSERT INTO
	departments(name)
VALUES
	('HR'),
	('Finance');

INSERT INTO
	employees(email, first_name, last_name, department_id)
VALUES
	('mary@test_co.com', 'Mary', 'Smith', (SELECT id from departments WHERE name='Finance')),
	('dave@test_co.com', 'Dave', 'Cole', (SELECT id from departments WHERE name='Finance')),
	('jane@test_co.com', 'Jane', 'Hills', (SELECT id from departments WHERE name='Finance')),
	('john@test_co.com', 'John', 'Doe', (SELECT id from departments WHERE name='HR'));
```

### Simple audit table

```SQL
CREATE OR REPLACE FUNCTION employees_audit_func()
	RETURNS TRIGGER
	AS $employees_audit$
BEGIN
	if (TG_OP = 'UPDATE') THEN
		INSERT INTO employees_audit
		SELECT
            uuid_generate_v4(),
			'UPDATE',
			now(),
			NEW.*;
	elsif (TG_OP = 'INSERT') THEN
		INSERT INTO employees_audit
		SELECT
            uuid_generate_v4(),
			'INSERT',
			now(),
			NEW.*;
    elsif (TG_OP = 'DELETE') THEN
		INSERT INTO employees_audit
		SELECT
            uuid_generate_v4(),
			'DELETE',
			now(),
			OLD.*;
	END IF;
	RETURN NULL;
END;
$employees_audit$
LANGUAGE plpgsql;

CREATE TRIGGER employees_audit_trigger
	AFTER INSERT OR UPDATE OR DELETE ON employees FOR EACH ROW
	EXECUTE PROCEDURE employees_audit_func();
```

### updated_at timestamp trigger

```SQL
CREATE OR REPLACE FUNCTION trigger_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_timestamp_employees
BEFORE UPDATE ON employees
FOR EACH ROW
EXECUTE PROCEDURE trigger_set_timestamp();
```

### Add column and foreign key constraint to existing table

```SQL
ALTER TABLE employees
ADD COLUMN department_id uuid DEFAULT NULL, -- Set to NOT NULL once data is populated
ADD CONSTRAINT employee_id_department_id FOREIGN KEY (department_id) REFERENCES departments(id);
```

Set column to `NOT NULL`

```SQL
ALTER TABLE employees ALTER COLUMN department_id SET NOT NULL;
```

### Alter table column type (with casting)

```SQL
CREATE TABLE employees (
	...
	employment_start_year VARCHAR(4) NOT NULL
	...
);

ALTER TABLE employees ALTER employment_start_year TYPE INT
USING employment_start_year::INTEGER;
```

### Update values with unnest

```SQL
UPDATE
	employees
SET
	email = data_table.email
FROM (
	SELECT
		unnest(ARRAY ['Mary', 'John', 'Dawn']) AS first_name,
		unnest(ARRAY ['Smith', 'Doe', 'Carter']) AS last_name) AS data_table
WHERE
	employees.email = data_table.email;
```

### JSON aggregation and functions

```SQL
SELECT
	dept.name AS department,
	jsonb_agg(
		DISTINCT jsonb_build_object (  -- DISTINCT to remove dupes
			'employee_id', e.id,
			'email', e.email,
			'first_name', e.first_name,
			'last_name', e.last_name
		)
	) AS department_staff
FROM
	employees e
	JOIN departments dept ON e.department_id = dept.id
GROUP BY
	d.name, d.id;
```

Returns:

| department | department_staff                                                                                                                                                                                                                                                                                                                                                                                      |
| ---------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Finance    | [{"email": "dave@test_co.com", "last_name": "Cole", "first_name": "Dave", "employee_id": "b26339e1-af22-4752-852e-cb51f342bb10"}, {"email": "jane@test_co.com", "last_name": "Hills", "first_name": "Jane", "employee_id": "710b5de9-f248-49d8-9846-57b31ed143b2"}, {"email": "mary@test_co.com", "last_name": "Smith", "first_name": "Mary", "employee_id": "e2044159-0576-4a3a-9fe5-9af24bf66102"}] |
| HR         | [{"email": "john@test_co.com", "last_name": "Doe", "first_name": "John", "employee_id": "bcdadb45-970e-4d87-8b8a-fab1ccfeddd4"}]                                                                                                                                                                                                                                                                      |

```SQL
SELECT
	d.name,
	jsonb_object_agg(e.email, (concat_ws(' ', e.first_name, e.last_name))) AS department_staff
FROM
	employees e
	JOIN departments d ON e.department_id = d.id
GROUP BY
	d.name,
	d.id;
```

Returns:

| department | department_staff                                                                                      |
| ---------- | ----------------------------------------------------------------------------------------------------- |
| Finance    | {"dave@test_co.com": "Dave Cole", "jane@test_co.com": "Jane Hills", "mary@test_co.com": "Mary Smith"} |
| HR         | {"john@test_co.com": "John Doe"}                                                                      |

### Get week number of a date

N.B. With last day of week is Saturady i.e. new week begins on Sunday

```SQL
CREATE OR REPLACE FUNCTION get_week_number_for_date (date_input date) RETURNS int LANGUAGE plpgsql AS $$ BEGIN RETURN (
		(
			$1 - DATE_TRUNC('year', $1)::date
		) + DATE_PART('isodow', DATE_TRUNC('year', $1))
	)::int / 7 + CASE
		WHEN DATE_PART('isodow', DATE_TRUNC('year', $1)) = 7 THEN 0
		ELSE 1
	END;
END;
$$;

get_week_number_for_date('2020-01-01');
```

### Count business days between 2 dates

```SQL
CREATE OR REPLACE FUNCTION business_days_count (from_date date, to_date date)
	RETURNS int
	LANGUAGE plpgsql
	AS $$
BEGIN
	RETURN (SELECT
		count(d::date) AS d
	FROM
		generate_series(from_date, to_date, '1 day'::interval) d
WHERE
	extract('dow' FROM d)
	NOT in(0, 6));
END;
$$;

```

### GENERATE_SERIES

`GENERATE_SERIES` is pretty handy when creating time-series dataset

```SQL
SELECT * FROM GENERATE_SERIES(2019, 2021, 1) AS "year", GENERATE_SERIES(1, 12, 1) AS "month";
```

Will generate a year-month table

| year | month |
| ---- | ----- |
| 2019 | 1     |
| 2019 | 2     |
| ...  | ...   |
| 2019 | 12    |
| 2020 | 1     |
| 2020 | 2     |
| ...  | ...   |
| 2020 | 12    |
| 2021 | 1     |
| 2021 | 2     |
| ...  | ...   |
| 2021 | 12    |

...and can also produce a range of dates/time

```SQL
SELECT * FROM generate_series('2022-01-01','2022-01-02', INTERVAL '1 hour');
```

| generate_series          |
| ------------------------ |
| 2022-01-01T00:00:00.000Z |
| 2022-01-01T01:00:00.000Z |
| 2022-01-01T02:00:00.000Z |
| 2022-01-01T03:00:00.000Z |
| 2022-01-01T04:00:00.000Z |
| 2022-01-01T05:00:00.000Z |
| 2022-01-01T06:00:00.000Z |
| 2022-01-01T07:00:00.000Z |
| 2022-01-01T08:00:00.000Z |
| 2022-01-01T09:00:00.000Z |
| 2022-01-01T10:00:00.000Z |
| 2022-01-01T11:00:00.000Z |
| 2022-01-01T12:00:00.000Z |
| 2022-01-01T13:00:00.000Z |
| 2022-01-01T14:00:00.000Z |
| 2022-01-01T15:00:00.000Z |
| 2022-01-01T16:00:00.000Z |
| 2022-01-01T17:00:00.000Z |
| 2022-01-01T18:00:00.000Z |
| 2022-01-01T19:00:00.000Z |
| 2022-01-01T20:00:00.000Z |
| 2022-01-01T21:00:00.000Z |
| 2022-01-01T22:00:00.000Z |
| 2022-01-01T23:00:00.000Z |
| 2022-01-02T00:00:00.000Z |

... and add some random generated data

```SQL
SELECT random() as rand_figures, *
FROM generate_series('2022-01-01','2022-01-02', INTERVAL '1 hour');
```

| rand_figures       | generate_series          |
| ------------------ | ------------------------ |
| 0.203633273951709  | 2022-01-01T00:00:00.000Z |
| 0.571097886189818  | 2022-01-01T01:00:00.000Z |
| 0.629665858577937  | 2022-01-01T02:00:00.000Z |
| 0.0612306422553957 | 2022-01-01T03:00:00.000Z |
| 0.431237444281578  | 2022-01-01T04:00:00.000Z |
| 0.229508123826236  | 2022-01-01T05:00:00.000Z |
| 0.867487183306366  | 2022-01-01T06:00:00.000Z |
| 0.758365222252905  | 2022-01-01T07:00:00.000Z |
| 0.155569355469197  | 2022-01-01T08:00:00.000Z |
| 0.786357307806611  | 2022-01-01T09:00:00.000Z |
| 0.284404154401273  | 2022-01-01T10:00:00.000Z |
| 0.367461221758276  | 2022-01-01T11:00:00.000Z |
| 0.754724379163235  | 2022-01-01T12:00:00.000Z |
| 0.0396546637639403 | 2022-01-01T13:00:00.000Z |
| 0.276610609609634  | 2022-01-01T14:00:00.000Z |
| 0.96564608765766   | 2022-01-01T15:00:00.000Z |
| 0.127415937371552  | 2022-01-01T16:00:00.000Z |
| 0.110610570758581  | 2022-01-01T17:00:00.000Z |
| 0.764237959869206  | 2022-01-01T18:00:00.000Z |
| 0.24844411527738   | 2022-01-01T19:00:00.000Z |
| 0.0547867906279862 | 2022-01-01T20:00:00.000Z |
| 0.977096977643669  | 2022-01-01T21:00:00.000Z |
| 0.677903080359101  | 2022-01-01T22:00:00.000Z |
| 0.173856796696782  | 2022-01-01T23:00:00.000Z |
| 0.896873883903027  | 2022-01-02T00:00:00.000Z |

### Covert datetime/date/timestamp to string

```SQL
SELECT TO_CHAR(TIMESTAMP '2023-01-01 05:00:00', 'YYYY-MM-DD');
```

### Postgres upsert (INSERT INTO...ON CONFLICT... DO NOTHING/UPDATE SET...)

**DO NOTHING (`email` is unique)**

```SQL
INSERT INTO users (email, username, tel)
VALUES
	('user_one@email.com', 'i_am_user_one', '0123456789'),
	('user_two@email.com', 'i_am_user_two', '9876543210')
ON CONFLICT (email)
DO NOTHING;
```

**DO UPDATE SET (`email` is unique)**

```SQL
INSERT INTO users (email, username, tel)
VALUES
	('user_one@email.com', 'i_am_user_one', '0123456789'),
	('user_two@email.com', 'i_am_user_two', '9876543210')
ON CONFLICT (name)
DO UPDATE SET username = EXCLUDED.username, tel = EXCLUDED.tel;
```
