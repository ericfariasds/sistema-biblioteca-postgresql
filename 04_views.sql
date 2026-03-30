-- ============================================================
-- SISTEMA DE BIBLIOTECA - Views
-- ============================================================

-- ------------------------------------------------------------
-- VIEW 1: Livros com informações completas
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_livros AS
SELECT
    l.id,
    l.titulo,
    l.isbn,
    a.nome AS autor,
    c.nome AS categoria,
    l.ano_publicacao,
    l.editora,
    l.quantidade_total,
    l.quantidade_disponivel,
    CASE
        WHEN l.quantidade_disponivel = 0 THEN 'Indisponível'
        ELSE 'Disponível'
    END AS situacao
FROM livros l
JOIN autores a ON a.id = l.autor_id
LEFT JOIN categorias c ON c.id = l.categoria_id;


-- ------------------------------------------------------------
-- VIEW 2: Empréstimos ativos com detalhes
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_emprestimos_ativos AS
SELECT
    e.id AS emprestimo_id,
    m.nome AS membro,
    m.email,
    l.titulo AS livro,
    e.data_emprestimo,
    e.data_devolucao_prevista,
    CURRENT_DATE - e.data_devolucao_prevista AS dias_atraso,
    e.status
FROM emprestimos e
JOIN membros m ON m.id = e.membro_id
JOIN livros l ON l.id = e.livro_id
WHERE e.status IN ('ativo', 'atrasado')
ORDER BY e.data_devolucao_prevista;


-- ------------------------------------------------------------
-- VIEW 3: Multas em aberto
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_multas_abertas AS
SELECT
    mu.id AS multa_id,
    m.nome AS membro,
    m.email,
    l.titulo AS livro,
    e.data_devolucao_prevista,
    e.data_devolucao_real,
    mu.dias_atraso,
    mu.valor_por_dia,
    mu.valor_total
FROM multas mu
JOIN emprestimos e ON e.id = mu.emprestimo_id
JOIN membros m ON m.id = e.membro_id
JOIN livros l ON l.id = e.livro_id
WHERE mu.paga = FALSE
ORDER BY mu.valor_total DESC;


-- ------------------------------------------------------------
-- VIEW 4: Ranking de livros mais emprestados
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_livros_mais_emprestados AS
SELECT
    l.titulo,
    a.nome AS autor,
    COUNT(e.id) AS total_emprestimos
FROM emprestimos e
JOIN livros l ON l.id = e.livro_id
JOIN autores a ON a.id = l.autor_id
GROUP BY l.titulo, a.nome
ORDER BY total_emprestimos DESC;


-- ------------------------------------------------------------
-- VIEW 5: Membros com empréstimos em atraso
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_membros_em_atraso AS
SELECT
    m.id,
    m.nome,
    m.email,
    m.telefone,
    COUNT(e.id) AS emprestimos_atrasados,
    fn_total_multas_abertas(m.id) AS total_multas_abertas
FROM membros m
JOIN emprestimos e ON e.membro_id = m.id
WHERE e.status = 'atrasado'
GROUP BY m.id, m.nome, m.email, m.telefone
ORDER BY total_multas_abertas DESC;
