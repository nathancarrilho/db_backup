-- Script para inicializar a base de dados com dados de teste

-- Criar tabela de usuários
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Criar tabela de produtos
CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    stock INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Inserir dados de teste
INSERT INTO users (name, email) VALUES 
('Nathan Leal', 'nathan@example.com'),
('Nathan Leal2', 'nathan2@example.com'),
('Nathan Leal3', 'natha3@example.com');

INSERT INTO products (name, description, price, stock) VALUES 
('Produto A', 'Descrição do produto A', 19.99, 100),
('Produto B', 'Descrição do produto B', 29.99, 50),
('Produto C', 'Descrição do produto C', 39.99, 25);