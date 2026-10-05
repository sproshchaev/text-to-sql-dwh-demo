-- Учебная схема интернет-магазина. SQLite 3.
-- Типы намеренно упрощены: суммы — целые рубли, даты — строки ГГГГ-ММ-ДД.

CREATE TABLE orders (
  order_id    INTEGER PRIMARY KEY,
  customer_id INTEGER,
  created_at  TEXT,      -- дата создания заказа
  status      TEXT,      -- completed / pending / cancelled
  amount      INTEGER    -- сумма заказа, рубли
);

CREATE TABLE payments (
  payment_id INTEGER PRIMARY KEY,
  order_id   INTEGER,    -- связь с заказом не объявлена внешним ключом
  paid_at    TEXT,
  amount     INTEGER
);

CREATE TABLE refunds (
  refund_id   INTEGER PRIMARY KEY,
  order_id    INTEGER,
  refunded_at TEXT,
  amount      INTEGER
);
