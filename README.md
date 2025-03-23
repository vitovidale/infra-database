# infra-database

> Banco de dados PostgreSQL gerenciado no AWS RDS para o FastFood‑App

---

## Visão Geral

Este repositório contém o esquema e os dados iniciais do banco de dados do FastFood‑App. Usamos **Amazon RDS for PostgreSQL** pela sua gestão automática (backups, patches), alta disponibilidade e escalabilidade.

---

## Modelo de Dados

![Diagrama ER](https://github.com/user-attachments/assets/a53834c2-3fb9-4360-838e-fb80d7fefe31)

| Tabela        | Descrição                                                      |
|---------------|----------------------------------------------------------------|
| **categories**| Categorias fixas de produto (Lanche, Acompanhamento, Bebida, Sobremesa) |
| **products**  | Produtos disponíveis, vinculados a uma categoria               |
| **customers** | Informações de clientes (ID, nome, email único, senha hash)    |

---

## Deploy (via GitHub Actions)

Toda a criação da instância RDS + execução do script `init.sql` é feita automaticamente pelo workflow GitHub Actions.

### Como executar

1. No GitHub, abra este repositório → clique em **Actions**  
2. Selecione o workflow **Deploy DB**  
3. Clique em **Run workflow**

---
