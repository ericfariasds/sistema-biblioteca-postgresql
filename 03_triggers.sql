-- ============================================================
-- SISTEMA DE BIBLIOTECA - Triggers
-- ============================================================

-- ------------------------------------------------------------
-- TRIGGER 1: Atualiza quantidade disponível ao emprestar
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_diminuir_estoque()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE livros
    SET quantidade_disponivel = quantidade_disponivel - 1
    WHERE id = NEW.livro_id;

    IF (SELECT quantidade_disponivel FROM livros WHERE id = NEW.livro_id) < 0 THEN
        RAISE EXCEPTION 'Livro sem exemplares disponíveis para empréstimo.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_diminuir_estoque
AFTER INSERT ON emprestimos
FOR EACH ROW
EXECUTE FUNCTION fn_diminuir_estoque();


-- ------------------------------------------------------------
-- TRIGGER 2: Atualiza quantidade disponível ao devolver
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_devolver_livro()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'devolvido' AND OLD.status <> 'devolvido' THEN
        UPDATE livros
        SET quantidade_disponivel = quantidade_disponivel + 1
        WHERE id = NEW.livro_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_devolver_livro
AFTER UPDATE ON emprestimos
FOR EACH ROW
EXECUTE FUNCTION fn_devolver_livro();


-- ------------------------------------------------------------
-- TRIGGER 3: Gera multa automaticamente ao devolver com atraso
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_gerar_multa()
RETURNS TRIGGER AS $$
DECLARE
    v_dias_atraso INT;
    v_valor_total NUMERIC(10,2);
    v_valor_dia   NUMERIC(6,2) := 2.00;
BEGIN
    IF NEW.status = 'devolvido'
       AND OLD.status IS DISTINCT FROM 'devolvido'
       AND NEW.data_devolucao_real IS NOT NULL THEN
        v_dias_atraso := NEW.data_devolucao_real - NEW.data_devolucao_prevista;

        IF v_dias_atraso > 0 THEN
            v_valor_total := v_dias_atraso * v_valor_dia;

            INSERT INTO multas (emprestimo_id, dias_atraso, valor_por_dia, valor_total)
            VALUES (NEW.id, v_dias_atraso, v_valor_dia, v_valor_total);
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_gerar_multa
AFTER UPDATE ON emprestimos
FOR EACH ROW
EXECUTE FUNCTION fn_gerar_multa();


-- ------------------------------------------------------------
-- TRIGGER 4: Atualiza status para 'atrasado' automaticamente
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_verificar_atraso()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.data_devolucao_prevista < CURRENT_DATE AND NEW.status = 'ativo' THEN
        NEW.status := 'atrasado';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_verificar_atraso
BEFORE UPDATE ON emprestimos
FOR EACH ROW
EXECUTE FUNCTION fn_verificar_atraso();
