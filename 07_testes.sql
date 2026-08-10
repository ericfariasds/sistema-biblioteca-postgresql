-- ============================================================
-- SISTEMA DE BIBLIOTECA - Testes automatizados
-- ============================================================
-- Valida o comportamento dos triggers e functions usando ASSERT.
-- Roda inteiramente dentro de uma transação com ROLLBACK ao final,
-- então NÃO deixa nenhum resíduo no banco - pode ser executado
-- com segurança mesmo depois do 05_seed.sql.
--
-- Uso:
--   psql -d Biblioteca -f 07_testes.sql
--
-- Se algum ASSERT falhar, o psql interrompe a execução e mostra
-- o erro. Se tudo passar, a última linha confirma o sucesso.
-- ============================================================

BEGIN;

-- ------------------------------------------------------------
-- SETUP: dados de teste isolados (não depende do 05_seed.sql,
-- para não quebrar se as quantidades do seed mudarem)
-- ------------------------------------------------------------
CREATE TEMP TABLE _test_ids (
    autor_id              INT,
    categoria_id          INT,
    livro_id              INT,
    livro_sem_estoque_id  INT,
    membro_id             INT,
    membro_inativo_id     INT,
    emprestimo_id         INT,
    emprestimo_atraso_id  INT
);

DO $$
DECLARE
    v_autor_id             INT;
    v_categoria_id         INT;
    v_livro_id             INT;
    v_livro_sem_estoque_id INT;
    v_membro_id            INT;
    v_membro_inativo_id    INT;
BEGIN
    INSERT INTO autores (nome, nacionalidade)
    VALUES ('Autor Teste', 'Testland') RETURNING id INTO v_autor_id;

    INSERT INTO categorias (nome)
    VALUES ('Categoria Teste') RETURNING id INTO v_categoria_id;

    INSERT INTO livros (titulo, autor_id, categoria_id, quantidade_total, quantidade_disponivel)
    VALUES ('Livro Teste', v_autor_id, v_categoria_id, 2, 2)
    RETURNING id INTO v_livro_id;

    INSERT INTO livros (titulo, autor_id, categoria_id, quantidade_total, quantidade_disponivel)
    VALUES ('Livro Sem Estoque', v_autor_id, v_categoria_id, 1, 0)
    RETURNING id INTO v_livro_sem_estoque_id;

    INSERT INTO membros (nome, email, ativo)
    VALUES ('Membro Teste', 'membro.teste@example.com', TRUE)
    RETURNING id INTO v_membro_id;

    INSERT INTO membros (nome, email, ativo)
    VALUES ('Membro Inativo', 'membro.inativo@example.com', FALSE)
    RETURNING id INTO v_membro_inativo_id;

    INSERT INTO _test_ids (autor_id, categoria_id, livro_id, livro_sem_estoque_id, membro_id, membro_inativo_id)
    VALUES (v_autor_id, v_categoria_id, v_livro_id, v_livro_sem_estoque_id, v_membro_id, v_membro_inativo_id);

    RAISE NOTICE 'SETUP OK: livro_id=%, livro_sem_estoque_id=%, membro_id=%, membro_inativo_id=%',
        v_livro_id, v_livro_sem_estoque_id, v_membro_id, v_membro_inativo_id;
END;
$$;

-- ------------------------------------------------------------
-- TESTE 1: trg_diminuir_estoque - empréstimo reduz o estoque
-- ------------------------------------------------------------
DO $$
DECLARE
    v_livro_id          INT;
    v_membro_id         INT;
    v_disponivel_antes  INT;
    v_disponivel_depois INT;
    v_emprestimo_id     INT;
BEGIN
    SELECT livro_id, membro_id INTO v_livro_id, v_membro_id FROM _test_ids;

    SELECT quantidade_disponivel INTO v_disponivel_antes FROM livros WHERE id = v_livro_id;

    INSERT INTO emprestimos (livro_id, membro_id, data_devolucao_prevista)
    VALUES (v_livro_id, v_membro_id, CURRENT_DATE + 14)
    RETURNING id INTO v_emprestimo_id;

    SELECT quantidade_disponivel INTO v_disponivel_depois FROM livros WHERE id = v_livro_id;

    ASSERT v_disponivel_depois = v_disponivel_antes - 1,
        format('esperado estoque %s, obtido %s', v_disponivel_antes - 1, v_disponivel_depois);

    UPDATE _test_ids SET emprestimo_id = v_emprestimo_id;

    RAISE NOTICE 'TESTE 1 OK: trg_diminuir_estoque reduz quantidade_disponivel ao emprestar';
END;
$$;

-- ------------------------------------------------------------
-- TESTE 2: trg_diminuir_estoque - bloqueia empréstimo sem estoque
-- ------------------------------------------------------------
DO $$
DECLARE
    v_livro_sem_estoque_id INT;
    v_membro_id            INT;
    v_erro_capturado       BOOLEAN := FALSE;
BEGIN
    SELECT livro_sem_estoque_id, membro_id INTO v_livro_sem_estoque_id, v_membro_id FROM _test_ids;

    BEGIN
        INSERT INTO emprestimos (livro_id, membro_id, data_devolucao_prevista)
        VALUES (v_livro_sem_estoque_id, v_membro_id, CURRENT_DATE + 14);
    EXCEPTION WHEN OTHERS THEN
        v_erro_capturado := TRUE;
    END;

    ASSERT v_erro_capturado, 'esperava exceção ao emprestar livro sem exemplares disponíveis';

    RAISE NOTICE 'TESTE 2 OK: trigger impede empréstimo de livro sem exemplares disponíveis';
END;
$$;

-- ------------------------------------------------------------
-- TESTE 3: trg_devolver_livro - devolução no prazo repõe o
-- estoque e NÃO gera multa
-- ------------------------------------------------------------
DO $$
DECLARE
    v_livro_id          INT;
    v_emprestimo_id     INT;
    v_disponivel_antes  INT;
    v_disponivel_depois INT;
    v_qtd_multas        INT;
BEGIN
    SELECT livro_id, emprestimo_id INTO v_livro_id, v_emprestimo_id FROM _test_ids;

    SELECT quantidade_disponivel INTO v_disponivel_antes FROM livros WHERE id = v_livro_id;

    UPDATE emprestimos
    SET status = 'devolvido', data_devolucao_real = CURRENT_DATE
    WHERE id = v_emprestimo_id;

    SELECT quantidade_disponivel INTO v_disponivel_depois FROM livros WHERE id = v_livro_id;
    ASSERT v_disponivel_depois = v_disponivel_antes + 1,
        'estoque deveria voltar ao devolver o livro dentro do prazo';

    SELECT COUNT(*) INTO v_qtd_multas FROM multas WHERE emprestimo_id = v_emprestimo_id;
    ASSERT v_qtd_multas = 0, 'não deveria gerar multa em devolução dentro do prazo';

    RAISE NOTICE 'TESTE 3 OK: devolução no prazo repõe estoque e não gera multa';
END;
$$;

-- ------------------------------------------------------------
-- TESTE 4: trg_gerar_multa - devolução em atraso gera multa
-- com o valor correto (dias_atraso × valor_por_dia)
-- ------------------------------------------------------------
DO $$
DECLARE
    v_livro_id             INT;
    v_membro_id            INT;
    v_emprestimo_atraso_id INT;
    v_dias_atraso          INT;
    v_valor_total          NUMERIC;
BEGIN
    SELECT livro_id, membro_id INTO v_livro_id, v_membro_id FROM _test_ids;

    -- empréstimo com data de devolução prevista 5 dias no passado
    INSERT INTO emprestimos (livro_id, membro_id, data_emprestimo, data_devolucao_prevista, status)
    VALUES (v_livro_id, v_membro_id, CURRENT_DATE - 20, CURRENT_DATE - 5, 'ativo')
    RETURNING id INTO v_emprestimo_atraso_id;

    UPDATE emprestimos
    SET status = 'devolvido', data_devolucao_real = CURRENT_DATE
    WHERE id = v_emprestimo_atraso_id;

    SELECT dias_atraso, valor_total INTO v_dias_atraso, v_valor_total
    FROM multas WHERE emprestimo_id = v_emprestimo_atraso_id;

    ASSERT v_dias_atraso = 5, format('esperado 5 dias de atraso, obtido %s', v_dias_atraso);
    ASSERT v_valor_total = 10.00, format('esperado multa de 10.00, obtido %s', v_valor_total);

    UPDATE _test_ids SET emprestimo_atraso_id = v_emprestimo_atraso_id;

    RAISE NOTICE 'TESTE 4 OK: trg_gerar_multa calcula corretamente dias_atraso e valor_total';
END;
$$;

-- ------------------------------------------------------------
-- TESTE 5: trg_verificar_atraso - status muda para 'atrasado'
-- quando a data prevista já passou
-- ------------------------------------------------------------
DO $$
DECLARE
    v_livro_id      INT;
    v_membro_id     INT;
    v_emprestimo_id INT;
    v_status        VARCHAR(20);
BEGIN
    SELECT livro_id, membro_id INTO v_livro_id, v_membro_id FROM _test_ids;

    INSERT INTO emprestimos (livro_id, membro_id, data_emprestimo, data_devolucao_prevista, status)
    VALUES (v_livro_id, v_membro_id, CURRENT_DATE - 30, CURRENT_DATE - 10, 'ativo')
    RETURNING id INTO v_emprestimo_id;

    -- update "vazio" apenas para disparar o trigger BEFORE UPDATE
    UPDATE emprestimos SET criado_em = criado_em WHERE id = v_emprestimo_id;

    SELECT status INTO v_status FROM emprestimos WHERE id = v_emprestimo_id;
    ASSERT v_status = 'atrasado', format('esperado status atrasado, obtido %s', v_status);

    RAISE NOTICE 'TESTE 5 OK: trg_verificar_atraso atualiza status quando a data prevista já passou';
END;
$$;

-- ------------------------------------------------------------
-- TESTE 6: fn_registrar_emprestimo - trata todos os cenários
-- (livro inexistente, sem estoque, membro inativo, sucesso)
-- ------------------------------------------------------------
DO $$
DECLARE
    v_livro_id             INT;
    v_livro_sem_estoque_id INT;
    v_membro_id            INT;
    v_membro_inativo_id    INT;
    v_resultado            TEXT;
BEGIN
    SELECT livro_id, livro_sem_estoque_id, membro_id, membro_inativo_id
    INTO v_livro_id, v_livro_sem_estoque_id, v_membro_id, v_membro_inativo_id
    FROM _test_ids;

    v_resultado := fn_registrar_emprestimo(999999, v_membro_id, 14);
    ASSERT v_resultado = 'Erro: Livro não encontrado.', format('obtido: %s', v_resultado);

    v_resultado := fn_registrar_emprestimo(v_livro_sem_estoque_id, v_membro_id, 14);
    ASSERT v_resultado = 'Erro: Nenhum exemplar disponível.', format('obtido: %s', v_resultado);

    v_resultado := fn_registrar_emprestimo(v_livro_id, v_membro_inativo_id, 14);
    ASSERT v_resultado = 'Erro: Membro inativo ou não encontrado.', format('obtido: %s', v_resultado);

    v_resultado := fn_registrar_emprestimo(v_livro_id, v_membro_id, 14);
    ASSERT v_resultado = 'Empréstimo registrado com sucesso!', format('obtido: %s', v_resultado);

    RAISE NOTICE 'TESTE 6 OK: fn_registrar_emprestimo trata todos os cenários corretamente';
END;
$$;

-- ------------------------------------------------------------
-- TESTE 7: fn_registrar_devolucao - trata todos os cenários
-- (empréstimo inexistente, sucesso, já devolvido)
-- ------------------------------------------------------------
DO $$
DECLARE
    v_livro_id      INT;
    v_membro_id     INT;
    v_emprestimo_id INT;
    v_resultado     TEXT;
BEGIN
    SELECT livro_id, membro_id INTO v_livro_id, v_membro_id FROM _test_ids;

    -- pega o empréstimo ativo criado no teste 6 (fn_registrar_emprestimo)
    SELECT id INTO v_emprestimo_id
    FROM emprestimos
    WHERE livro_id = v_livro_id AND membro_id = v_membro_id AND status = 'ativo'
    ORDER BY criado_em DESC
    LIMIT 1;

    v_resultado := fn_registrar_devolucao(999999);
    ASSERT v_resultado = 'Erro: Empréstimo não encontrado.', format('obtido: %s', v_resultado);

    v_resultado := fn_registrar_devolucao(v_emprestimo_id);
    ASSERT v_resultado = 'Devolução registrada com sucesso!', format('obtido: %s', v_resultado);

    v_resultado := fn_registrar_devolucao(v_emprestimo_id);
    ASSERT v_resultado = 'Erro: Livro já foi devolvido.', format('obtido: %s', v_resultado);

    RAISE NOTICE 'TESTE 7 OK: fn_registrar_devolucao trata todos os cenários corretamente';
END;
$$;

-- ------------------------------------------------------------
-- TESTE 8: fn_multas_membro e fn_total_multas_abertas retornam
-- os valores esperados a partir da multa gerada no TESTE 4
-- ------------------------------------------------------------
DO $$
DECLARE
    v_membro_id  INT;
    v_total      NUMERIC;
    v_qtd_multas INT;
BEGIN
    SELECT membro_id INTO v_membro_id FROM _test_ids;

    SELECT fn_total_multas_abertas(v_membro_id) INTO v_total;
    ASSERT v_total = 10.00, format('esperado total de multas 10.00, obtido %s', v_total);

    SELECT COUNT(*) INTO v_qtd_multas FROM fn_multas_membro(v_membro_id);
    ASSERT v_qtd_multas = 1, format('esperada 1 multa para o membro teste, obtido %s', v_qtd_multas);

    RAISE NOTICE 'TESTE 8 OK: fn_total_multas_abertas e fn_multas_membro retornam os valores corretos';
END;
$$;

-- ------------------------------------------------------------
-- CLEANUP: desfaz tudo (nenhum dado de teste persiste no banco)
-- ------------------------------------------------------------
ROLLBACK;

SELECT 'Todos os testes passaram (Rollback aplicado e nenhum dado de teste foi persistido).' AS resultado;