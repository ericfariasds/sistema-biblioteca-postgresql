#  Sistema de Biblioteca 📚 - SQL

Projeto de banco de dados relacional para gerenciamento de uma biblioteca, desenvolvido com **PostgreSQL**. Cobre modelagem de dados, automação via triggers, funções reutilizáveis e views de consulta.

## Estrutura do Projeto

## Estrutura do Projeto

```
biblioteca/
├── README.md
├── 01_create_tables.sql   # Tabelas, constraints e índices
├── 02_functions.sql       # Funções reutilizáveis (empréstimo, devolução, multas)
├── 03_triggers.sql        # Automação de estoque, multas e status
├── 04_views.sql           # Views para consultas comuns
├── 05_seed.sql            # Dados de exemplo
└── 06_consultas.sql       # Consultas de demonstração
```

## Tabelas

| Tabela | Descrição |
|---|---|
| `autores` | Cadastro de autores dos livros |
| `categorias` | Categorias/gêneros dos livros |
| `livros` | Acervo da biblioteca |
| `membros` | Membros cadastrados |
| `emprestimos` | Registro de empréstimos e devoluções |
| `multas` | Multas por atraso na devolução |

## Funcionalidades

### Triggers
- `trg_diminuir_estoque` - reduz `quantidade_disponivel` ao registrar um empréstimo, e impede empréstimo sem exemplares
- `trg_devolver_livro` - devolve o exemplar ao estoque quando o status muda para `devolvido`
- `trg_gerar_multa` - calcula e insere multa automaticamente quando a devolução ocorre com atraso
- `trg_verificar_atraso` - atualiza o status para `atrasado` quando a data prevista já passou

### Functions
- `fn_registrar_emprestimo(livro_id, membro_id, dias)` - registra um novo empréstimo, validando disponibilidade e status do membro
- `fn_registrar_devolucao(emprestimo_id)` - registra a devolução de um empréstimo
- `fn_multas_membro(membro_id)` - lista as multas associadas a um membro
- `fn_total_multas_abertas(membro_id)` - retorna o total em aberto de um membro

### Views
- `vw_livros` - livros com autor, categoria e disponibilidade
- `vw_emprestimos_ativos` - empréstimos em andamento, com dias de atraso calculados
- `vw_multas_abertas` - multas não pagas
- `vw_livros_mais_emprestados` - ranking de popularidade
- `vw_membros_em_atraso` - membros com pendências e total devido

## Como executar

```bash
# 1. Criar o banco de dados
createdb Biblioteca

# 2. Executar os scripts na ordem numerada
psql -d Biblioteca -f 01_create_tables.sql
psql -d Biblioteca -f 02_functions.sql
psql -d Biblioteca -f 03_triggers.sql
psql -d Biblioteca -f 04_views.sql
psql -d Biblioteca -f 05_seed.sql

# 3. Testar as consultas de exemplo
psql -d Biblioteca -f 06_consultas.sql
```

## Tecnologias

- PostgreSQL 12+
- PL/pgSQL

## Autor

**Eric Farias**
GitHub: [@ericfariasds](https://github.com/ericfariasds)