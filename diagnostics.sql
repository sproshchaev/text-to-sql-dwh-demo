-- Объём данных
SELECT 'orders',  COUNT(*) FROM orders;
SELECT 'payments', COUNT(*) FROM payments;
SELECT 'refunds', COUNT(*) FROM refunds;
SELECT 'orders_paid_in_two_parts', COUNT(*)
FROM (SELECT order_id FROM payments GROUP BY order_id HAVING COUNT(*) > 1);

-- Разбор запроса B, ошибка 1: заказы сентября, задвоенные соединением
SELECT 'B_doubled_by_join', COUNT(*)
FROM (SELECT o.order_id
      FROM orders o
      JOIN payments p ON p.order_id = o.order_id
      WHERE o.status = 'completed'
        AND o.created_at >= '2026-09-01' AND o.created_at < '2026-10-01'
      GROUP BY o.order_id
      HAVING COUNT(*) > 1);

-- Разбор запроса B, ошибка 2: заказы сентября, оплаченные уже в октябре
SELECT 'B_paid_in_october', COUNT(DISTINCT o.order_id)
FROM orders o
JOIN payments p ON p.order_id = o.order_id
WHERE o.status = 'completed'
  AND o.created_at >= '2026-09-01' AND o.created_at < '2026-10-01'
  AND p.paid_at >= '2026-10-01';
