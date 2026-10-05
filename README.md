# text-to-sql-dwh-demo

[![check](https://github.com/sproshchaev/text-to-sql-dwh-demo/actions/workflows/check.yml/badge.svg)](https://github.com/sproshchaev/text-to-sql-dwh-demo/actions/workflows/check.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Учебный эксперимент к статье на Хабре
«[Почему AI-аналитик отвечает на учебных данных и путается на вашем хранилище](https://habr.com/ru/companies/otus/articles/1088874/)».

Один вопрос бизнеса — «Какая выручка за сентябрь?» — и три правдоподобных SQL-запроса,
которые мог бы написать и человек, и AI-агент, глядя только на схему. Все три выполняются
без ошибок. Все три дают разные числа.

## Быстрый старт

Нужен только `sqlite3`.

```bash
git clone https://github.com/sproshchaev/text-to-sql-dwh-demo.git
cd text-to-sql-dwh-demo
./run.sh
```

`run.sh` собирает базу `demo.db` с нуля, печатает результаты и сверяет их с `expected.txt`.

Без скрипта, вручную:

```bash
sqlite3 demo.db < schema.sql
sqlite3 demo.db < seed.sql
sqlite3 demo.db < queries.sql
```

## Результат

| Запрос | Что считает | Результат | Отклонение от C |
|---|---|---:|---:|
| A | все заказы сентября по дате создания | 4 465 500 | +23,6% |
| B | завершённые заказы, соединённые с платежами | 4 623 500 | +28,0% |
| C | чистые поступления: оплаты минус возвраты по дате движения денег | 3 613 500 | — |

Запрос B выглядит строже A — отменённые заказы отброшены, — а результат больше. У него две
независимые ошибки (`diagnostics.sql`):

1. **Соединение размножает строки.** У `payments` другое зерно: одна строка — один платёж.
   Заказ на 20 000, оплаченный двумя платежами по 10 000, после `JOIN` превращается в две
   строки, и `SUM(o.amount)` даёт 40 000. Так задвоились 138 сентябрьских заказов.
2. **Не та дата.** Запрос задуман «про оплаты», а фильтр стоит по дате заказа: 44 заказа,
   созданные в сентябре, оплачены уже в октябре и всё равно попали в сумму.

Запрос C — не «правильная выручка», а одно из корректных определений. В другой компании
выручкой назовут сумму отгрузок без НДС. Смысл эксперимента в том, что правильный ответ
задаёт договорённость, а её в схеме нет.

## Данные

| Таблица | Строк | Что внутри |
|---|---:|---|
| `orders` | 1 000 | заказы с 25.08 по 30.09.2026: completed, pending, cancelled |
| `payments` | 1 035 | 165 заказов оплачены двумя платежами, часть оплат уходит в октябрь |
| `refunds` | 42 | полные возвраты через 1–10 дней после оплаты |

Типы намеренно упрощены: суммы — целые рубли, даты — строки `ГГГГ-ММ-ДД`. Связь
`payments.order_id → orders.order_id` специально не объявлена внешним ключом, как это нередко
бывает в аналитических хранилищах. Периоды в запросах заданы полуинтервалами (`>= '2026-09-01' AND
< '2026-10-01'`), чтобы не зависеть от наличия времени в дате.

Данные синтетические и показывают **механику** ошибки, а не её вероятность в продакшене.
Проценты отклонений — свойство этих данных, а не типичная погрешность.

## Структура

```
.
├── schema.sql              # DDL: orders, payments, refunds
├── seed.sql                # готовые данные, сгенерированы generate_seed.py
├── generate_seed.py        # генератор, seed=141, только стандартная библиотека
├── queries.sql             # запросы A, B, C
├── diagnostics.sql         # объём данных и разбор ошибок запроса B
├── run.sh                  # сборка базы, вывод, сверка с expected.txt
├── expected.txt            # эталонный вывод
└── semantic_layer/
    └── net_cash_collected.yml  # метрика C в dbt Semantic Layer (иллюстрация)
```

## Изменить данные

```bash
python3 generate_seed.py > seed.sql   # поменяйте SEED или распределения в скрипте
./run.sh                              # покажет расхождение с expected.txt
```

CI на каждый push проверяет две вещи: `seed.sql` воспроизводится генератором байт в байт,
и `run.sh` выдаёт ровно `expected.txt`.

## Семантический слой

`semantic_layer/net_cash_collected.yml` — метрика C, описанная в актуальной спецификации
dbt Semantic Layer. В описании записаны зерно каждой таблицы и определение показателя, а у
каждой простой метрики своя дата агрегации: `paid` по `paid_at`, `refunded` по `refunded_at`.

Это фрагмент для иллюстрации подхода, а не готовый dbt-проект: компиляция через dbt здесь
не проверяется.

## Источники

- Spider 2.0: Evaluating Language Models on Real-World Enterprise Text-to-SQL Workflows (ICLR 2025) — https://arxiv.org/abs/2411.07763
- BEAVER: An Enterprise Benchmark for Text-to-SQL — https://arxiv.org/abs/2409.02038
- M. Stonebraker, P. B. Chen. If You Think You Can Do Real-World Text-to-SQL. Communications of the ACM, 2026 — https://cacm.acm.org/research/if-you-think-you-can-do-real-world-text-to-sql/
- dbt Semantic Layer: semantic models — https://docs.getdbt.com/docs/build/semantic-models

## Лицензия

[MIT](LICENSE)
