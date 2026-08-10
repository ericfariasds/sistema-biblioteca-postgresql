# 📚 Sistema de Biblioteca - SQL

Esse é um projeto de banco de dados relacional que fiz pra praticar modelagem de dados, automação com triggers e escrita de queries mais robustas em PostgreSQL. A ideia foi simular um sistema real de biblioteca: cadastro de livros, empréstimos, devoluções e controle de multas por atraso.

## Estrutura do Projeto

Numerei os scripts na ordem em que eles precisam ser executados:

```
biblioteca/
├── README.md
├── er-diagram.md          # Diagrama ER (Mermaid)
├── .gitignore
├── 01_create_tables.sql   # Tabelas, constraints e índices
├── 02_functions.sql       # Funções reutilizáveis (empréstimo, devolução, multas)
├── 03_triggers.sql        # Automação de estoque, multas e status
├── 04_views.sql           # Views para consultas comuns
├── 05_seed.sql            # Dados de exemplo
├── 06_consultas.sql       # Consultas de demonstração
└── 07_testes.sql          # Testes automatizados (triggers e functions)
```

## Modelo de Dados

| Tabela | Descrição |
|---|---|
| `autores` | Cadastro de autores dos livros |
| `categorias` | Categorias/gêneros dos livros |
| `livros` | Acervo da biblioteca |
| `membros` | Membros cadastrados |
| `emprestimos` | Registro de empréstimos e devoluções |
| `multas` | Multas por atraso na devolução |

**Relacionamentos principais:** um autor tem vários livros (`1:N`), um livro pode pertencer a uma categoria (`N:1`, opcional), um membro pode ter vários empréstimos (`1:N`), e cada empréstimo pode gerar no máximo uma multa (`1:1` quando há atraso).

📎 Diagrama ER completo, com atributos e cardinalidades: [`er-diagram.md`](./er-diagram.md)

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

## Decisões de design

Algumas escolhas que fiz de propósito, e o porquê:
 
- **Coloquei a lógica de negócio no banco (triggers/functions) em vez de deixar pra aplicação**: estoque, status de atraso e geração de multa são regras centrais desse domínio. Preferi manter isso no banco pra garantir consistência não importa qual aplicação esteja inserindo os dados (web, mobile, script).
- **Usei `ON DELETE RESTRICT` em `livros` e `membros`**: não faz sentido deixar excluir um autor ou livro que já tem histórico de empréstimo, perderia rastreabilidade. Já em `categoria_id` usei `ON DELETE SET NULL`, porque categoria é só uma classificação secundária, então não precisa travar a exclusão por causa dela.
- **Criei índices explícitos nas FKs**: aprendi que o PostgreSQL não cria índice automático em chave estrangeira (diferente da chave primária). Como `emprestimos` é a tabela mais consultada via `JOIN` (dá pra ver isso em `04_views.sql`), coloquei índices em `livro_id`, `membro_id` e `status` pra evitar sequential scan conforme a tabela crescer.
- **Usei `CHECK` constraints direto na tabela** em vez de validar só na aplicação: assim a integridade fica garantida mesmo se alguém inserir direto no banco (ex: `data_devolucao_prevista` sempre depois de `data_emprestimo`, quantidades nunca negativas).

## Testes automatizados

Escrevi o `07_testes.sql` pra validar o comportamento de todos os triggers e functions usando `ASSERT`. Ele cobre:
 
- Redução e reposição de estoque ao emprestar/devolver
- Bloqueio de empréstimo quando não há exemplares disponíveis
- Geração automática de multa (com o cálculo certo do valor) em devoluções atrasadas
- Atualização automática de status para `atrasado`
- Todos os caminhos de erro e sucesso de `fn_registrar_emprestimo` e `fn_registrar_devolucao`
- Retorno correto de `fn_multas_membro` e `fn_total_multas_abertas`
O script inteiro roda dentro de uma transação com `ROLLBACK` no final, então não deixa nenhum dado de teste no banco, dá pra rodar com segurança mesmo depois de já ter carregado o `05_seed.sql`.
 
```bash
psql -d Biblioteca -f 07_testes.sql
```
 
Se algum `ASSERT` falhar, o `psql` para a execução e mostra o erro. Se passar tudo, a última linha confirma o sucesso.

![Testes passando no pgAdmin](../biblioteca-sql/testMessages.png)

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

# 4. (Opcional) Rodar os testes automatizados
psql -d Biblioteca -f 07_testes.sql
```

## Tecnologias

- PostgreSQL 12+
- PL/pgSQL

## 👤 Autor

**Eric Farias**
GitHub: [@ericfariasds](https://github.com/ericfariasds)