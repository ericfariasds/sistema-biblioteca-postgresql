-- ============================================================
-- SISTEMA DE BIBLIOTECA - Schema Principal
-- Autor: Eric
-- Descrição: Criação das tabelas do sistema de biblioteca
-- ============================================================

CREATE DATABASE IF NOT EXISTS Biblioteca;
\c Biblioteca;

-- ============================================================
-- TABELA: autores
-- ============================================================
CREATE TABLE autores (
    id          SERIAL PRIMARY KEY,
    nome        VARCHAR(150) NOT NULL,
    nacionalidade VARCHAR(100),
    data_nascimento DATE,
    biografia   TEXT,
    criado_em   TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- TABELA: categorias
-- ============================================================
CREATE TABLE categorias (
    id    SERIAL PRIMARY KEY,
    nome  VARCHAR(100) NOT NULL UNIQUE,
    descricao TEXT
);

-- ============================================================
-- TABELA: livros
-- ============================================================
CREATE TABLE livros (
    id            SERIAL PRIMARY KEY,
    titulo        VARCHAR(200) NOT NULL,
    isbn          VARCHAR(20) UNIQUE,
    autor_id      INT NOT NULL REFERENCES autores(id) ON DELETE RESTRICT,
    categoria_id  INT REFERENCES categorias(id) ON DELETE SET NULL,
    ano_publicacao INT,
    editora       VARCHAR(150),
    quantidade_total   INT NOT NULL DEFAULT 1,
    quantidade_disponivel INT NOT NULL DEFAULT 1,
    criado_em     TIMESTAMP DEFAULT NOW(),
    CONSTRAINT chk_quantidade CHECK (quantidade_disponivel >= 0 AND quantidade_total >= 0)
);

-- ============================================================
-- TABELA: membros
-- ============================================================
CREATE TABLE membros (
    id          SERIAL PRIMARY KEY,
    nome        VARCHAR(150) NOT NULL,
    email       VARCHAR(150) UNIQUE NOT NULL,
    telefone    VARCHAR(20),
    endereco    TEXT,
    data_cadastro DATE DEFAULT CURRENT_DATE,
    ativo       BOOLEAN DEFAULT TRUE,
    criado_em   TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- TABELA: emprestimos
-- ============================================================
CREATE TABLE emprestimos (
    id              SERIAL PRIMARY KEY,
    livro_id        INT NOT NULL REFERENCES livros(id) ON DELETE RESTRICT,
    membro_id       INT NOT NULL REFERENCES membros(id) ON DELETE RESTRICT,
    data_emprestimo DATE NOT NULL DEFAULT CURRENT_DATE,
    data_devolucao_prevista DATE NOT NULL,
    data_devolucao_real     DATE,
    status          VARCHAR(20) DEFAULT 'ativo'
                    CHECK (status IN ('ativo', 'devolvido', 'atrasado')),
    criado_em       TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- TABELA: multas
-- ============================================================
CREATE TABLE multas (
    id              SERIAL PRIMARY KEY,
    emprestimo_id   INT NOT NULL REFERENCES emprestimos(id) ON DELETE RESTRICT,
    dias_atraso     INT NOT NULL DEFAULT 0,
    valor_por_dia   NUMERIC(6,2) NOT NULL DEFAULT 2.00,
    valor_total     NUMERIC(10,2),
    paga            BOOLEAN DEFAULT FALSE,
    data_pagamento  DATE,
    criado_em       TIMESTAMP DEFAULT NOW()
);
