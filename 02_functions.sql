-- ============================================================
-- SISTEMA DE BIBLIOTECA - Functions
-- ============================================================

-- ------------------------------------------------------------
-- FUNCTION 1: Registrar empréstimo
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_registrar_emprestimo(
    p_livro_id  INT,
    p_membro_id INT,
    p_dias      INT DEFAULT 14
)
RETURNS TEXT AS $$
DECLARE
    v_disponivel INT;
    v_membro_ativo BOOLEAN;
BEGIN
    SELECT quantidade_disponivel INTO v_disponivel
    FROM livros WHERE id = p_livro_id;

    IF v_disponivel IS NULL THEN
        RETURN 'Erro: Livro não encontrado.';
    END IF;

    IF v_disponivel = 0 THEN
        RETURN 'Erro: Nenhum exemplar disponível.';
    END IF;

    SELECT ativo INTO v_membro_ativo
    FROM membros WHERE id = p_membro_id;

    IF NOT v_membro_ativo THEN
        RETURN 'Erro: Membro inativo ou não encontrado.';
    END IF;

    INSERT INTO emprestimos (livro_id, membro_id, data_devolucao_prevista)
    VALUES (p_livro_id, p_membro_id, CURRENT_DATE + p_dias);

    RETURN 'Empréstimo registrado com sucesso!';
END;
$$ LANGUAGE plpgsql;


-- ------------------------------------------------------------
-- FUNCTION 2: Registrar devolução
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_registrar_devolucao(p_emprestimo_id INT)
RETURNS TEXT AS $$
DECLARE
    v_status VARCHAR(20);
BEGIN
    SELECT status INTO v_status
    FROM emprestimos WHERE id = p_emprestimo_id;

    IF v_status IS NULL THEN
        RETURN 'Erro: Empréstimo não encontrado.';
    END IF;

    IF v_status = 'devolvido' THEN
        RETURN 'Erro: Livro já foi devolvido.';
    END IF;

    UPDATE emprestimos
    SET status = 'devolvido',
        data_devolucao_real = CURRENT_DATE
    WHERE id = p_emprestimo_id;

    RETURN 'Devolução registrada com sucesso!';
END;
$$ LANGUAGE plpgsql;


-- ------------------------------------------------------------
-- FUNCTION 3: Consultar multas em aberto de um membro
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_multas_membro(p_membro_id INT)
RETURNS TABLE (
    emprestimo_id INT,
    livro         TEXT,
    dias_atraso   INT,
    valor_total   NUMERIC,
    paga          BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        m.emprestimo_id,
        l.titulo::TEXT,
        m.dias_atraso,
        m.valor_total,
        m.paga
    FROM multas m
    JOIN emprestimos e ON e.id = m.emprestimo_id
    JOIN livros l ON l.id = e.livro_id
    WHERE e.membro_id = p_membro_id;
END;
$$ LANGUAGE plpgsql;


-- ------------------------------------------------------------
-- FUNCTION 4: Total de multas em aberto por membro
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_total_multas_abertas(p_membro_id INT)
RETURNS NUMERIC AS $$
DECLARE
    v_total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(m.valor_total), 0) INTO v_total
    FROM multas m
    JOIN emprestimos e ON e.id = m.emprestimo_id
    WHERE e.membro_id = p_membro_id AND m.paga = FALSE;

    RETURN v_total;
END;
$$ LANGUAGE plpgsql;
