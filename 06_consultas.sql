-- ============================================================
-- SISTEMA DE BIBLIOTECA - Consultas Úteis
-- ============================================================

-- 1. Listar todos os livros disponíveis
SELECT titulo, autor, categoria, quantidade_disponivel
FROM vw_livros
WHERE situacao = 'Disponível';

-- 2. Listar empréstimos ativos
SELECT * FROM vw_emprestimos_ativos;

-- 3. Ver multas em aberto
SELECT * FROM vw_multas_abertas;

-- 4. Ranking de livros mais emprestados
SELECT * FROM vw_livros_mais_emprestados;

-- 5. Membros com atraso
SELECT * FROM vw_membros_em_atraso;

-- 6. Registrar um novo empréstimo (livro_id=6, membro_id=2, 14 dias)
SELECT fn_registrar_emprestimo(6, 2, 14);

-- 7. Registrar devolução (emprestimo_id=3)
SELECT fn_registrar_devolucao(3);

-- 8. Ver multas de um membro específico
SELECT * FROM fn_multas_membro(1);

-- 9. Total de multas abertas de um membro
SELECT fn_total_multas_abertas(1) AS total_devido;

-- 10. Buscar livros por autor
SELECT titulo, categoria, situacao
FROM vw_livros
WHERE autor ILIKE '%Tolkien%';

-- 11. Histórico completo de empréstimos de um membro
SELECT
    l.titulo,
    e.data_emprestimo,
    e.data_devolucao_prevista,
    e.data_devolucao_real,
    e.status
FROM emprestimos e
JOIN livros l ON l.id = e.livro_id
WHERE e.membro_id = 1
ORDER BY e.data_emprestimo DESC;

-- 12. Relatório geral da biblioteca
SELECT
    (SELECT COUNT(*) FROM livros) AS total_livros,
    (SELECT SUM(quantidade_disponivel) FROM livros) AS exemplares_disponiveis,
    (SELECT COUNT(*) FROM membros WHERE ativo = TRUE) AS membros_ativos,
    (SELECT COUNT(*) FROM emprestimos WHERE status IN ('ativo','atrasado')) AS emprestimos_em_andamento,
    (SELECT COALESCE(SUM(valor_total),0) FROM multas WHERE paga = FALSE) AS total_multas_abertas;
