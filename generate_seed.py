#!/usr/bin/env python3
"""Генератор seed.sql для эксперимента «три запроса на один вопрос».

Только стандартная библиотека. Seed фиксирован (141), поэтому файл
воспроизводится байт в байт. Готовый seed.sql лежит в репозитории,
запускать генератор нужно только если хотите поменять распределение.

    python3 generate_seed.py > seed.sql
"""
import datetime
import random

SEED = 141
ORDERS = 1000
AMOUNTS = [1500, 2500, 4000, 7000, 12000]  # целые рубли

random.seed(SEED)
orders, payments, refunds = [], [], []
payment_id = refund_id = 0

for order_id in range(1, ORDERS + 1):
    # заказы с 25 августа по 30 сентября 2026
    day = random.randint(0, 36)
    created = (f"2026-08-{25 + day:02d}" if day < 7
               else f"2026-09-{day - 6:02d}")
    amount = random.choice(AMOUNTS)
    r = random.random()
    status = ("cancelled" if r < 0.08
              else "pending" if r < 0.13
              else "completed")
    customer_id = random.randint(1, 400)
    orders.append((order_id, customer_id, created, status, amount))
    if status != "completed":
        continue

    # оплата в день заказа или до трёх дней позже, может уйти в октябрь
    paid = (datetime.date.fromisoformat(created)
            + datetime.timedelta(days=random.randint(0, 3)))
    if random.random() < 0.2:  # 20% заказов оплачены двумя платежами
        half = amount // 2
        for part in (half, amount - half):
            payment_id += 1
            payments.append((payment_id, order_id, paid.isoformat(), part))
    else:
        payment_id += 1
        payments.append((payment_id, order_id, paid.isoformat(), amount))

    if random.random() < 0.06:  # полный возврат через 1-10 дней
        refunded = paid + datetime.timedelta(days=random.randint(1, 10))
        refund_id += 1
        refunds.append((refund_id, order_id, refunded.isoformat(), amount))


def emit(table, rows):
    print(f"INSERT INTO {table} VALUES")
    print(",\n".join(
        "(" + ", ".join(repr(v) if isinstance(v, str) else str(v) for v in row) + ")"
        for row in rows) + ";")


print(f"-- Сгенерировано generate_seed.py, seed={SEED}. Не править руками.")
print("BEGIN;")
emit("orders", orders)
emit("payments", payments)
emit("refunds", refunds)
print("COMMIT;")
