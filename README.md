# 📚 Sistema de Biblioteca - SQL

Projeto de banco de dados relacional para gerenciamento de uma biblioteca, desenvolvido com **PostgreSQL**.

## 🗂️ Estrutura do Projeto

```
biblioteca/
├── README.md
├── schema/
│   ├── create_tables.sql   # Criação das tabelas
│   ├── triggers.sql        # Triggers automáticos
│   ├── functions.sql       # Funções reutilizáveis
│   └── views.sql           # Views para consultas
├── data/
│   └── seed.sql            # Dados de exemplo
└── queries/
    └── consultas.sql       # Consultas úteis
```

## 🗄️ Tabelas

| Tabela | Descrição |
|---|---|
| `autores` | Cadastro de autores dos livros |
| `categorias` | Categorias/gêneros dos livros |
| `livros` | Acervo da biblioteca |
| `membros` | Membros cadastrados |
| `emprestimos` | Registro de empréstimos e devoluções |
| `multas` | Multas por atraso na devolução |

## ⚙️ Funcionalidades

### Triggers
- Atualiza estoque automaticamente ao emprestar/devolver
- Gera multa automaticamente ao devolver com atraso
- Atualiza status para `atrasado` quando a data passa

### Functions
- `fn_registrar_emprestimo(livro_id, membro_id, dias)` — Registra um novo empréstimo
- `fn_registrar_devolucao(emprestimo_id)` — Registra a devolução
- `fn_multas_membro(membro_id)` — Lista multas de um membro
- `fn_total_multas_abertas(membro_id)` — Retorna total de multas em aberto

### Views
- `vw_livros` — Livros com autor, categoria e disponibilidade
- `vw_emprestimos_ativos` — Empréstimos em andamento
- `vw_multas_abertas` — Multas não pagas
- `vw_livros_mais_emprestados` — Ranking de popularidade
- `vw_membros_em_atraso` — Membros com pendências

## 🚀 Como executar

```bash
# 1. Criar o banco de dados
createdb Biblioteca

# 2. Criar as tabelas
psql -d Biblioteca -f schema/create_tables.sql

# 3. Criar as functions
psql -d Biblioteca -f schema/functions.sql

# 4. Criar os triggers
psql -d Biblioteca -f schema/triggers.sql

# 5. Criar as views
psql -d Biblioteca -f schema/views.sql

# 6. Inserir dados de exemplo
psql -d Biblioteca -f data/seed.sql

# 7. Testar as consultas
psql -d Biblioteca -f queries/consultas.sql
```

## 🛠️ Tecnologias

- PostgreSQL 12+
- PL/pgSQL

## 👤 Autor

Eric Farias
