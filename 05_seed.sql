-- ============================================================
-- SISTEMA DE BIBLIOTECA - Dados de Exemplo (Seed)
-- ============================================================

-- Categorias
INSERT INTO categorias (nome, descricao) VALUES
('Ficção Científica', 'Livros de ficção com base em ciência e tecnologia'),
('Romance', 'Histórias de amor e relacionamentos'),
('Terror', 'Livros de suspense e horror'),
('Fantasia', 'Mundos e criaturas fantásticas'),
('Programação', 'Livros técnicos de desenvolvimento de software'),
('História', 'Livros sobre eventos históricos');

-- Autores
INSERT INTO autores (nome, nacionalidade, data_nascimento) VALUES
('George Orwell', 'Britânico', '1903-06-25'),
('J.R.R. Tolkien', 'Britânico', '1892-01-03'),
('Stephen King', 'Americano', '1947-09-21'),
('Machado de Assis', 'Brasileiro', '1839-06-21'),
('Robert C. Martin', 'Americano', '1952-12-05'),
('Isaac Asimov', 'Americano', '1920-01-02');

-- Livros
INSERT INTO livros (titulo, isbn, autor_id, categoria_id, ano_publicacao, editora, quantidade_total, quantidade_disponivel) VALUES
('1984', '978-0451524935', 1, 1, 1949, 'Secker & Warburg', 3, 3),
('A Revolução dos Bichos', '978-0452284241', 1, 1, 1945, 'Secker & Warburg', 2, 2),
('O Senhor dos Anéis', '978-0618640157', 2, 4, 1954, 'Allen & Unwin', 4, 4),
('O Hobbit', '978-0547928227', 2, 4, 1937, 'Allen & Unwin', 3, 3),
('It - A Coisa', '978-1501156700', 3, 3, 1986, 'Viking Press', 2, 2),
('O Iluminado', '978-0385121675', 3, 3, 1977, 'Doubleday', 2, 2),
('Dom Casmurro', '978-8535902778', 4, 2, 1899, 'Garnier', 3, 3),
('Código Limpo', '978-0132350884', 5, 5, 2008, 'Prentice Hall', 2, 2),
('Fundação', '978-0553293357', 6, 1, 1951, 'Gnome Press', 3, 3),
('Eu, Robô', '978-0553294385', 6, 1, 1950, 'Gnome Press', 2, 2);

-- Membros
INSERT INTO membros (nome, email, telefone, endereco) VALUES
('Ana Paula Silva', 'ana.silva@email.com', '21999990001', 'Rua das Flores, 10 - Rio de Janeiro'),
('Carlos Eduardo Santos', 'carlos.santos@email.com', '21999990002', 'Av. Brasil, 200 - Rio de Janeiro'),
('Fernanda Lima', 'fernanda.lima@email.com', '21999990003', 'Rua Copacabana, 55 - Rio de Janeiro'),
('João Pedro Oliveira', 'joao.oliveira@email.com', '21999990004', 'Rua Ipanema, 88 - Rio de Janeiro'),
('Mariana Costa', 'mariana.costa@email.com', '21999990005', 'Av. Atlântica, 300 - Rio de Janeiro');

-- Empréstimos (alguns já devolvidos, alguns ativos, um com atraso)
INSERT INTO emprestimos (livro_id, membro_id, data_emprestimo, data_devolucao_prevista, data_devolucao_real, status) VALUES
(1, 1, CURRENT_DATE - 30, CURRENT_DATE - 16, CURRENT_DATE - 10, 'devolvido'),
(3, 2, CURRENT_DATE - 20, CURRENT_DATE - 6,  CURRENT_DATE - 8, 'devolvido'),
(5, 3, CURRENT_DATE - 10, CURRENT_DATE + 4,  NULL, 'ativo'),
(8, 4, CURRENT_DATE - 5,  CURRENT_DATE + 9,  NULL, 'ativo'),
(9, 5, CURRENT_DATE - 25, CURRENT_DATE - 11, CURRENT_DATE - 5, 'devolvido'),
(2, 1, CURRENT_DATE - 40, CURRENT_DATE - 26, NULL, 'atrasado');
