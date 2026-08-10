# Diagrama ER - Sistema de Biblioteca

```mermaid
erDiagram
    AUTORES ||--o{ LIVROS : "escreve"
    CATEGORIAS |o--o{ LIVROS : "classifica"
    LIVROS ||--o{ EMPRESTIMOS : "e_emprestado_em"
    MEMBROS ||--o{ EMPRESTIMOS : "realiza"
    EMPRESTIMOS ||--o| MULTAS : "gera"

    AUTORES {
        int id PK
        varchar nome
        varchar nacionalidade
        date data_nascimento
        text biografia
        timestamp criado_em
    }

    CATEGORIAS {
        int id PK
        varchar nome UK
        text descricao
    }

    LIVROS {
        int id PK
        varchar titulo
        varchar isbn UK
        int autor_id FK
        int categoria_id FK
        int ano_publicacao
        varchar editora
        int quantidade_total
        int quantidade_disponivel
        timestamp criado_em
    }

    MEMBROS {
        int id PK
        varchar nome
        varchar email UK
        varchar telefone
        text endereco
        date data_cadastro
        boolean ativo
        timestamp criado_em
    }

    EMPRESTIMOS {
        int id PK
        int livro_id FK
        int membro_id FK
        date data_emprestimo
        date data_devolucao_prevista
        date data_devolucao_real
        varchar status
        timestamp criado_em
    }

    MULTAS {
        int id PK
        int emprestimo_id FK
        int dias_atraso
        numeric valor_por_dia
        numeric valor_total
        boolean paga
        date data_pagamento
        timestamp criado_em
    }
```

## Cardinalidades

| Relacionamento | Cardinalidade | Observação |
|---|---|---|
| Autor → Livros | 1:N | Um autor pode ter vários livros; todo livro tem exatamente um autor (`NOT NULL`) |
| Categoria → Livros | 1:N (opcional) | `categoria_id` aceita `NULL` (`ON DELETE SET NULL`) |
| Livro → Empréstimos | 1:N | Um livro pode ter vários empréstimos ao longo do tempo |
| Membro → Empréstimos | 1:N | Um membro pode ter vários empréstimos |
| Empréstimo → Multa | 1:0-ou-1 | Gerada automaticamente por trigger apenas quando há atraso na devolução |
