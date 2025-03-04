--Categories
create table categories
(
    id         varchar(36)              not null
        primary key,
    name       varchar(60)              not null,
    created_at timestamp with time zone not null,
    updated_at timestamp with time zone,
    deleted_at timestamp with time zone
);

alter table categories
    owner to postgres;

INSERT INTO public.categories (id, name, created_at, updated_at, deleted_at) VALUES ('5f501e6d-e29a-441d-baba-fc01b27921bf', 'Lanche', '2024-11-05 23:05:29.411851 +00:00', '2024-11-05 23:05:29.411851 +00:00', null);
INSERT INTO public.categories (id, name, created_at, updated_at, deleted_at) VALUES ('43539b3f-c054-4b81-8bd6-e564543fb3bf', 'Acompanhamento', '2024-11-05 23:05:34.806386 +00:00', '2024-11-05 23:05:34.806386 +00:00', null);
INSERT INTO public.categories (id, name, created_at, updated_at, deleted_at) VALUES ('f6b7a75f-3873-434e-8e90-6ea65c5fef7d', 'Bebida', '2024-11-05 23:05:41.438945 +00:00', '2024-11-05 23:05:41.438945 +00:00', null);
INSERT INTO public.categories (id, name, created_at, updated_at, deleted_at) VALUES ('4e927a50-204a-446c-9297-fe228a9261e8', 'Sobremesa', '2024-11-05 23:05:47.629794 +00:00', '2024-11-05 23:05:47.629794 +00:00', null);

--
-- products
create table products
(
    id          varchar(36)              not null
        primary key,
    name        varchar(60)              not null,
    description varchar(100),
    price       numeric                  not null,
    category_id varchar(36)              not null
        constraint fk_products_category
            references categories,
    created_at  timestamp with time zone not null,
    updated_at  timestamp with time zone,
    deleted_at  timestamp with time zone
);

alter table products
    owner to postgres;

INSERT INTO public.products (id, name, description, price, category_id, created_at, updated_at, deleted_at) VALUES ('71c2ab50-792e-4a1a-aefb-9aca87dd9b5a', 'Coca Cola', 'Refrigerente Coca Cola 600 Ml', 6, 'f6b7a75f-3873-434e-8e90-6ea65c5fef7d', '2024-11-05 23:10:15.389713 +00:00', '2024-11-05 23:10:15.389713 +00:00', null);
INSERT INTO public.products (id, name, description, price, category_id, created_at, updated_at, deleted_at) VALUES ('4760f943-8c3e-48a8-bf88-393cea9bbfd2', 'Fritas', 'Bata Frita Media', 15, '43539b3f-c054-4b81-8bd6-e564543fb3bf', '2024-11-05 23:12:06.765074 +00:00', '2024-11-05 23:12:06.765074 +00:00', null);
INSERT INTO public.products (id, name, description, price, category_id, created_at, updated_at, deleted_at) VALUES ('6be9044f-1a16-42ee-a66b-c047f25c0fe7', 'Sorvete Casca', 'Sorvete casquinha', 5, '4e927a50-204a-446c-9297-fe228a9261e8', '2024-11-05 23:13:28.047833 +00:00', '2024-11-05 23:13:28.047833 +00:00', null);
INSERT INTO public.products (id, name, description, price, category_id, created_at, updated_at, deleted_at) VALUES ('54aa4024-ddae-43e9-a89a-e4d3e1e9d972', 'cheeseburger bacon', 'hamburger cheeseburger bacon artesanal', 30, '5f501e6d-e29a-441d-baba-fc01b27921bf', '2024-11-05 23:15:43.444668 +00:00', '2024-11-05 23:15:43.444668 +00:00', null);

--

--Customers
create table customers
(
    id         bigserial
        primary key,
    first_name varchar(100)             not null,
    last_name  varchar(100)             not null,
    email      varchar(255)             not null
        constraint uni_customers_email
            unique,
    password   varchar(64)              not null,
    created_at timestamp with time zone not null,
    updated_at timestamp with time zone,
    deleted_at timestamp with time zone
);

alter table customers
    owner to postgres;

INSERT INTO public.customers (id, first_name, last_name, email, password, created_at, updated_at, deleted_at) VALUES (12345678910, 'Fabio', 'Pontes', 'fabio.pontes@example.com', '$2a$10$kGxCi8dd5kUmfFsV5GLnGuKLggJ5yF.Gb8ea7Ocoyb2/UAjcHFdpq', '2024-11-05 23:07:04.603323 +00:00', '2024-11-05 23:07:04.603323 +00:00', null);
