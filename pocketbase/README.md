# PocketBase — бэкенд курсового проекта armory_last

Платформа вместо самописного сервера (по заданию итогового проекта серверный
код писать не нужно). Схема — 8 связанных сущностей оружейного магазина, все
три типа связей, ролевой доступ и одно содержательное доменное правило
(см. ниже) заданы миграциями в `pb_migrations/` и применяются автоматически
при первом запуске.

## Установка/запуск

Бинарник в `pocketbase/pocketbase` не хранится в git (см. `.gitignore` в
корне проекта) — скачивается заново:

```bash
cd armory_last/pocketbase
curl -sL -o pb.zip \
  https://github.com/pocketbase/pocketbase/releases/download/v0.40.4/pocketbase_0.40.4_linux_amd64.zip
unzip -o pb.zip pocketbase && rm pb.zip && chmod +x pocketbase
```

Запуск (миграции из `pb_migrations/` применяются автоматически):

```bash
./pocketbase serve --http=127.0.0.1:8090
```

Первый суперпользователь (панель `/_/`) создаётся один раз:

```bash
./pocketbase superuser upsert admin@armory.local <пароль>
```

REST API — `http://127.0.0.1:8090/api/`, Dashboard — `http://127.0.0.1:8090/_/`.

## Схема (8 сущностей)

| Коллекция | Тип связи | Назначение |
|---|---|---|
| `manufacturers` | 1:M → weapons | Производитель |
| `categories` | M:M ↔ weapons | Категория (несёт `license_type`, нужен для правила ниже) |
| `designers` | M:M ↔ weapons | Конструктор |
| `weapons` | M:1 → manufacturers, M:M → categories/designers | Оружие |
| `stores` | 1:M → orders | Магазин/филиал |
| `clients` | 1:1 → users (аккаунт покупателя), 1:M → orders | Покупатель |
| `licenses` | **1:1** → clients | Разрешение на оружие (тип/срок действия) |
| `orders` | M:1 → clients/weapons/stores | Заказ |

`users` (встроенная auth-коллекция) дополнена полями `role`
(`buyer`/`seller`/`admin`) и ФИО раздельно: `last_name`/`first_name`
(обязательные), `patronymic` (необязательное — не у всех есть отчество).
Одна учётная запись обслуживает все три роли, поэтому ФИО лежит здесь, а
не в `clients` — `clients.full_name`/`email` намеренно не заводились:
это были бы те же самые данные во втором месте (нарушение атомарности —
`full_name` одной строкой — плюс лишняя избыточность), экраны читают их
через `expand=user`.

## Роли и доступ

Все правила — в `pb_migrations/1789735205_schema.js` (`listRule`/`createRule`/…
на каждой коллекции), не в коде клиента. Чтение справочников — любая
залогиненная роль; запись справочников — seller+; hard delete — только
admin. `clients`/`licenses`/`orders` дополнительно проверяют владельца
(`client.user = @request.auth.id`) — покупатель видит только своё.
Публичная регистрация (`users.createRule`) может создать только роль
`buyer` — `seller`/`admin` заводит исключительно уже залогиненный админ.

**Содержательное доменное правило (п.20 задания)**: `orders.createRule`
проверяет, что у покупателя есть **действующая** (по `expires_at`)
лицензия, чей `type` покрывает **хотя бы одну** из категорий заказываемого
оружия — целиком на стороне PocketBase, через relation-фильтр
(`client.licenses_via_client.type ?= weapon.categories.license_type`), без
единой строчки серверного кода. Проверено вживую: заказ оружия категории,
покрытой лицензией — 200, заказ не покрытой категории — 400.

## Тестовые аккаунты (после `pb_migrations/1789735300_seed.js`)

| Логин | Пароль | Роль |
|---|---|---|
| pokupatel@armory.test | Buyer123! | buyer (привязан к тестовому клиенту с rifle-лицензией) |
| prodavec@armory.test | Seller123! | seller |
| admin@armory.test | Admin123! | admin |

Сид также заводит 3 производителей, 4 категории, 2 конструкторов, 2
магазина, 3 единицы оружия и один демонстрационный заказ.

## Известные пробелы / что дальше

- `pubspec.yaml` получил зависимость `pocketbase` (Dart-клиент), но слой
  `lib/repositories/api_*_repository.dart` и `lib/core/api_client.dart`
  всё ещё написаны под старый Go-бэкенд (`armory_api`, Dio) — их предстоит
  переписать поверх `PocketBase`-клиента. Интерфейсы репозиториев
  (`WeaponRepository` и т.д.) не меняются — по замыслу задания это третья
  по счёту реализация одного и того же интерфейса.
- `License`/`Store` — новые сущности, у них ещё нет моделей/экранов в
  `lib/`.
- `AuthNotifier`/`router.dart` рассчитаны на токены собственного сервера
  (access/refresh), PocketBase выдаёт один auth-токен с собственным
  механизмом обновления — логику входа/сессии придётся адаптировать.
