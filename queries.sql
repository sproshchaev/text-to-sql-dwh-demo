-- Вопрос бизнеса: «Какая выручка за сентябрь?»
-- Три правдоподобных ответа. Все выполняются без ошибок, числа разные.

-- A. «Самый очевидный»: сумма заказов, созданных в сентябре. Зерно — заказ.
SELECT 'A', SUM(amount)
FROM orders
WHERE created_at >= '2026-09-01'
  AND created_at <  '2026-10-01';

-- B. «Аккуратный»: раз показатель связан с оплатой — присоединить payments,
--    отменённые заказы отбросить. Две ошибки: join размножает строки
--    (у payments зерно — платёж), фильтр стоит по дате заказа, а не оплаты.
SELECT 'B', SUM(o.amount)
FROM orders o
JOIN payments p ON p.order_id = o.order_id
WHERE o.status = 'completed'
  AND o.created_at >= '2026-09-01'
  AND o.created_at <  '2026-10-01';

-- C. Другая бизнес-договорённость — чистые поступления денег:
--    поступило в сентябре минус возвращено в сентябре, по дате движения денег.
--    Это не универсальная «выручка», а одно из корректных определений.
SELECT 'C',
  COALESCE((SELECT SUM(amount) FROM payments
            WHERE paid_at >= '2026-09-01' AND paid_at < '2026-10-01'), 0)
  -
  COALESCE((SELECT SUM(amount) FROM refunds
            WHERE refunded_at >= '2026-09-01' AND refunded_at < '2026-10-01'), 0)
  AS net_cash_collected;
