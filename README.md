# infra-database

> Infraestrutura de banco de dados para o FastFood‑App — PostgreSQL gerenciado no AWS RDS

---

## 📖 Visão Geral

Este repositório contém tudo o que você precisa para provisionar, documentar e popular o esquema de dados do FastFood‑App. O banco escolhido foi o **Amazon RDS for PostgreSQL**, pela sua confiabilidade, escalabilidade automática, backups integrados e facilidade de manutenção.

---

## 🗂 Modelo de Dados

O esquema atual possui três entidades principais:

| Tabela       | Descrição                                                       |
|--------------|-----------------------------------------------------------------|
| **categories** | Categorias fixas de produto (Lanche, Acompanhamento, Bebida, Sobremesa) |
| **products**   | Produtos disponíveis, vinculados a uma categoria              |
| **customers**  | Dados de clientes (identificação, email único, senha criptografada) |

### Diagrama ER

![Diagrama ER do banco](https://github.com/user-attachments/assets/a53834c2-3fb9-4360-838e-fb80d7fefe31)

---

## 🚀 Provisionamento

### Pré‑requisitos

- Conta AWS com permissões para criar instâncias RDS
- Terraform (>=1.4.x) instalado localmente

### Terraform

```bash
cd infra-database/terraform
terraform init
terraform apply -auto-approve
