CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS departments (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NULL
);

CREATE TABLE IF NOT EXISTS employees (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    first_name VARCHAR(255) NOT NULL,
    last_name VARCHAR(255) NOT NULL,
    department_id uuid NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NULL,
    FOREIGN KEY (department_id) REFERENCES departments(id) ON DELETE CASCADE
);

INSERT INTO
    departments(name)
VALUES
    ('HR'), ('Finance');

INSERT INTO
    employees(email, first_name, last_name, department_id)
VALUES
    ('mary@test_co.com', 'Mary', 'Smith', (SELECT id from departments WHERE name='Finance')),
    ('dave@test_co.com', 'Dave', 'Cole', (SELECT id from departments WHERE name='Finance')),
    ('jane@test_co.com', 'Jane', 'Hills', (SELECT id from departments WHERE name='Finance')),
    ('john@test_co.com', 'John', 'Doe', (SELECT id from departments WHERE name='HR'));
