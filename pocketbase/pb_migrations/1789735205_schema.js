/// <reference path="../pb_data/types.d.ts" />

// Схема курсового проекта "оружейный магазин" (armory_last).
// 8 сущностей, все три типа связей:
//   1:1  Client <-> License
//   1:M  Manufacturer -> Weapon, Store -> Order, Client -> Order
//   M:M  Weapon <-> Category, Weapon <-> Designer
//
// Логическое удаление — свои поля is_deleted/deleted_at (обновляются через
// updateRule). Физическое удаление — обычный DELETE записи PocketBase
// (deleteRule). Ссылочную целостность при физическом удалении (запрет
// удалить производителя/категорию/конструктора/оружие/клиента, на которые
// ссылаются другие активные записи) PocketBase проверяет сам по умолчанию
// (cascadeDelete: false на всех relation-полях ниже).

const LICENSE_TYPES = ["rifle", "shotgun", "pistol", "other"];

migrate((app) => {
  // --- users: добавляем роль и ФИО к встроенной auth-коллекции ---
  const users = app.findCollectionByNameOrId("users");
  users.fields.add(new Field({
    name: "role",
    type: "select",
    required: true,
    values: ["buyer", "seller", "admin"],
    maxSelect: 1,
  }));
  // ФИО раздельно (3НФ/1НФ: атомарные значения, а не одна строка) —
  // одна учётная запись обслуживает все три роли (buyer/seller/admin),
  // поэтому поля тут, а не дублируются в clients.
  users.fields.add(new Field({ name: "last_name", type: "text", required: true, max: 100 }));
  users.fields.add(new Field({ name: "first_name", type: "text", required: true, max: 100 }));
  users.fields.add(new Field({ name: "patronymic", type: "text", max: 100 }));
  // Публичная регистрация создаёт только buyer (роль в теле запроса
  // обязана быть "buyer", если запрос не от уже залогиненного админа) —
  // иначе кто угодно мог бы зарегистрироваться сразу админом.
  users.createRule = "@request.body.role = \"buyer\" || @request.auth.role = \"admin\"";
  // Список всех пользователей — только сам себя или админ (нужен для
  // управления ролями). Просмотр ОДНОЙ записи — ещё и seller: без этого
  // `expand=client.user` в заказах молча обрезает имя покупателя, когда
  // список открывает продавец (PocketBase убирает из expand то, что
  // запрашивающий не имеет права посмотреть отдельно), а продавцу как раз
  // нужно видеть, кому выдавать оружие.
  users.listRule = "id = @request.auth.id || @request.auth.role = \"admin\"";
  users.viewRule = "id = @request.auth.id || @request.auth.role = \"admin\" || @request.auth.role = \"seller\"";
  // Роль меняет только админ; сам пользователь может редактировать
  // остальные свои поля — проверка честная через :isset, а не через кэш
  // на клиенте (в отличие от намеренно уязвимого места в ПР5).
  users.updateRule = "id = @request.auth.id && @request.body.role:isset = false || @request.auth.role = \"admin\"";
  users.deleteRule = "@request.auth.role = \"admin\"";
  app.save(users);

  // --- manufacturers ---
  const manufacturers = new Collection({
    type: "base",
    name: "manufacturers",
    listRule: "@request.auth.id != ''",
    viewRule: "@request.auth.id != ''",
    createRule: "@request.auth.role = \"seller\" || @request.auth.role = \"admin\"",
    updateRule: "@request.auth.role = \"seller\" || @request.auth.role = \"admin\"",
    deleteRule: "@request.auth.role = \"admin\"",
    fields: [
      { name: "created", type: "autodate", onCreate: true },
      { name: "updated", type: "autodate", onCreate: true, onUpdate: true },
      { name: "name", type: "text", required: true, min: 1, max: 200 },
      { name: "country", type: "text", max: 100 },
      { name: "founded", type: "number", onlyInt: true, min: 1300, max: 2100 },
      { name: "is_deleted", type: "bool" },
      { name: "deleted_at", type: "date" },
    ],
    indexes: [
      "CREATE UNIQUE INDEX idx_manufacturers_name ON manufacturers (name) WHERE is_deleted = false",
    ],
  });
  app.save(manufacturers);

  // --- categories ---
  const categories = new Collection({
    type: "base",
    name: "categories",
    listRule: "@request.auth.id != ''",
    viewRule: "@request.auth.id != ''",
    createRule: "@request.auth.role = \"seller\" || @request.auth.role = \"admin\"",
    updateRule: "@request.auth.role = \"seller\" || @request.auth.role = \"admin\"",
    deleteRule: "@request.auth.role = \"admin\"",
    fields: [
      { name: "created", type: "autodate", onCreate: true },
      { name: "updated", type: "autodate", onCreate: true, onUpdate: true },
      { name: "name", type: "text", required: true, min: 1, max: 200 },
      {
        name: "license_type", type: "select", required: true,
        values: LICENSE_TYPES, maxSelect: 1,
      },
      { name: "is_deleted", type: "bool" },
      { name: "deleted_at", type: "date" },
    ],
    indexes: [
      "CREATE UNIQUE INDEX idx_categories_name ON categories (name) WHERE is_deleted = false",
    ],
  });
  app.save(categories);

  // --- designers ---
  const designers = new Collection({
    type: "base",
    name: "designers",
    listRule: "@request.auth.id != ''",
    viewRule: "@request.auth.id != ''",
    createRule: "@request.auth.role = \"seller\" || @request.auth.role = \"admin\"",
    updateRule: "@request.auth.role = \"seller\" || @request.auth.role = \"admin\"",
    deleteRule: "@request.auth.role = \"admin\"",
    fields: [
      { name: "created", type: "autodate", onCreate: true },
      { name: "updated", type: "autodate", onCreate: true, onUpdate: true },
      { name: "full_name", type: "text", required: true, min: 1, max: 200 },
      { name: "country", type: "text", max: 100 },
      { name: "active_since", type: "number", onlyInt: true, min: 1300, max: 2100 },
      { name: "is_deleted", type: "bool" },
      { name: "deleted_at", type: "date" },
    ],
    indexes: [
      "CREATE UNIQUE INDEX idx_designers_full_name ON designers (full_name) WHERE is_deleted = false",
    ],
  });
  app.save(designers);

  // --- stores ---
  const stores = new Collection({
    type: "base",
    name: "stores",
    listRule: "@request.auth.id != ''",
    viewRule: "@request.auth.id != ''",
    createRule: "@request.auth.role = \"seller\" || @request.auth.role = \"admin\"",
    updateRule: "@request.auth.role = \"seller\" || @request.auth.role = \"admin\"",
    deleteRule: "@request.auth.role = \"admin\"",
    fields: [
      { name: "created", type: "autodate", onCreate: true },
      { name: "updated", type: "autodate", onCreate: true, onUpdate: true },
      { name: "name", type: "text", required: true, min: 1, max: 200 },
      { name: "address", type: "text", max: 300 },
      { name: "is_deleted", type: "bool" },
      { name: "deleted_at", type: "date" },
    ],
    indexes: [
      "CREATE UNIQUE INDEX idx_stores_name ON stores (name) WHERE is_deleted = false",
    ],
  });
  app.save(stores);

  // --- weapons (M:1 manufacturer, M:M categories, M:M designers) ---
  const weapons = new Collection({
    type: "base",
    name: "weapons",
    listRule: "@request.auth.id != ''",
    viewRule: "@request.auth.id != ''",
    createRule: "@request.auth.role = \"seller\" || @request.auth.role = \"admin\"",
    // Продавец/админ правят что угодно. Любой залогиненный (включая buyer)
    // может тронуть ТОЛЬКО stock_available (и ничего больше в теле запроса)
    // — единственная лазейка, нужная для списания/возврата остатка при
    // заказе/отмене без серверного кода. PocketBase не поддерживает
    // арифметику вида "поле - 1" внутри правил, поэтому точность "ровно
    // ±1" правило не проверяет — это осознанное упрощение (гонка при двух
    // одновременных заказах на последнюю единицу описана в
    // pb_order_repository.dart и в отчёте).
    updateRule: "@request.auth.role = \"seller\" || @request.auth.role = \"admin\" || (@request.auth.id != '' && @request.body.stock_available:isset = true && @request.body.name:isset = false && @request.body.sku:isset = false && @request.body.manufacturer:isset = false && @request.body.categories:isset = false && @request.body.designers:isset = false && @request.body.caliber:isset = false && @request.body.year:isset = false && @request.body.price:isset = false && @request.body.stock_total:isset = false)",
    deleteRule: "@request.auth.role = \"admin\"",
    fields: [
      { name: "created", type: "autodate", onCreate: true },
      { name: "updated", type: "autodate", onCreate: true, onUpdate: true },
      { name: "name", type: "text", required: true, min: 1, max: 200 },
      { name: "sku", type: "text", required: true, min: 1, max: 50 },
      {
        name: "manufacturer", type: "relation", required: true,
        collectionId: manufacturers.id, cascadeDelete: false, maxSelect: 1,
      },
      {
        name: "categories", type: "relation", required: true,
        collectionId: categories.id, cascadeDelete: false, minSelect: 1, maxSelect: 20,
      },
      {
        name: "designers", type: "relation",
        collectionId: designers.id, cascadeDelete: false, maxSelect: 20,
      },
      { name: "caliber", type: "text", max: 50 },
      { name: "year", type: "number", onlyInt: true, min: 1300, max: 2100 },
      { name: "price", type: "number", min: 0 },
      { name: "stock_total", type: "number", onlyInt: true, min: 0, required: true },
      { name: "stock_available", type: "number", onlyInt: true, min: 0, required: true },
      { name: "is_deleted", type: "bool" },
      { name: "deleted_at", type: "date" },
    ],
    indexes: [
      "CREATE UNIQUE INDEX idx_weapons_sku ON weapons (sku) WHERE is_deleted = false",
    ],
  });
  app.save(weapons);

  // --- clients (1:1 user, привязка к аккаунту покупателя) ---
  const clients = new Collection({
    type: "base",
    name: "clients",
    listRule: "@request.auth.role = \"seller\" || @request.auth.role = \"admin\" || user = @request.auth.id",
    viewRule: "@request.auth.role = \"seller\" || @request.auth.role = \"admin\" || user = @request.auth.id",
    createRule: "@request.auth.id != '' && (user = @request.auth.id || @request.auth.role = \"seller\" || @request.auth.role = \"admin\")",
    updateRule: "@request.auth.role = \"seller\" || @request.auth.role = \"admin\" || user = @request.auth.id",
    deleteRule: "@request.auth.role = \"admin\"",
    fields: [
      { name: "created", type: "autodate", onCreate: true },
      { name: "updated", type: "autodate", onCreate: true, onUpdate: true },
      {
        name: "user", type: "relation", required: true,
        collectionId: users.id, cascadeDelete: false, maxSelect: 1,
      },
      // ФИО/email намеренно НЕ дублируются здесь — они уже есть в
      // связанном users (1:1 через user). Дублирование было бы лишней
      // избыточностью: два места хранения одного факта расходятся при
      // редактировании только одного из них. Экраны читают их через
      // expand=user.
      { name: "phone", type: "text", max: 30 },
      { name: "is_deleted", type: "bool" },
      { name: "deleted_at", type: "date" },
    ],
    indexes: [
      "CREATE UNIQUE INDEX idx_clients_user ON clients (user)",
    ],
  });
  app.save(clients);

  // --- licenses (1:1 client — настоящее разрешение на оружие) ---
  const licenses = new Collection({
    type: "base",
    name: "licenses",
    listRule: "@request.auth.role = \"seller\" || @request.auth.role = \"admin\" || client.user = @request.auth.id",
    viewRule: "@request.auth.role = \"seller\" || @request.auth.role = \"admin\" || client.user = @request.auth.id",
    createRule: "@request.auth.role = \"seller\" || @request.auth.role = \"admin\"",
    updateRule: "@request.auth.role = \"seller\" || @request.auth.role = \"admin\"",
    deleteRule: "@request.auth.role = \"admin\"",
    fields: [
      { name: "created", type: "autodate", onCreate: true },
      { name: "updated", type: "autodate", onCreate: true, onUpdate: true },
      {
        name: "client", type: "relation", required: true,
        collectionId: clients.id, cascadeDelete: false, maxSelect: 1,
      },
      { name: "number", type: "text", required: true, max: 50 },
      {
        name: "type", type: "select", required: true,
        values: LICENSE_TYPES, maxSelect: 1,
      },
      { name: "issued_at", type: "date", required: true },
      { name: "expires_at", type: "date", required: true },
    ],
    indexes: [
      "CREATE UNIQUE INDEX idx_licenses_client ON licenses (client)",
      "CREATE UNIQUE INDEX idx_licenses_number ON licenses (number)",
    ],
  });
  app.save(licenses);

  // --- orders (M:1 client, M:1 weapon, M:1 store) ---
  const orders = new Collection({
    type: "base",
    name: "orders",
    listRule: "@request.auth.role = \"seller\" || @request.auth.role = \"admin\" || client.user = @request.auth.id",
    viewRule: "@request.auth.role = \"seller\" || @request.auth.role = \"admin\" || client.user = @request.auth.id",
    // Содержательное правило предметной области: заказ проходит, только
    // если у покупателя есть действующая (по сроку) лицензия, чей тип
    // покрывает хотя бы одну из категорий заказываемого оружия. "?="
    // — оператор "хотя бы одно совпадение" для relation/select-полей,
    // licenses_via_client — обратная связь license.client -> clients.
    createRule: "@request.auth.id != '' && client.user = @request.auth.id && client.licenses_via_client.type ?= weapon.categories.license_type && client.licenses_via_client.expires_at > @now",
    updateRule: "@request.auth.role = \"seller\" || @request.auth.role = \"admin\" || (client.user = @request.auth.id && status = \"ordered\")",
    deleteRule: "@request.auth.role = \"admin\"",
    fields: [
      { name: "created", type: "autodate", onCreate: true },
      { name: "updated", type: "autodate", onCreate: true, onUpdate: true },
      {
        name: "client", type: "relation", required: true,
        collectionId: clients.id, cascadeDelete: false, maxSelect: 1,
      },
      {
        name: "weapon", type: "relation", required: true,
        collectionId: weapons.id, cascadeDelete: false, maxSelect: 1,
      },
      {
        name: "store", type: "relation", required: true,
        collectionId: stores.id, cascadeDelete: false, maxSelect: 1,
      },
      {
        name: "status", type: "select", required: true,
        values: ["ordered", "picked_up", "cancelled"], maxSelect: 1,
      },
      { name: "serial_number", type: "text", max: 100 },
      { name: "picked_up_at", type: "date" },
      { name: "is_deleted", type: "bool" },
      { name: "deleted_at", type: "date" },
    ],
  });
  app.save(orders);
}, (app) => {
  for (const name of ["orders", "licenses", "clients", "weapons", "stores", "designers", "categories", "manufacturers"]) {
    const c = app.findCollectionByNameOrId(name);
    if (c) app.delete(c);
  }

  const users = app.findCollectionByNameOrId("users");
  users.fields.removeByName("role");
  users.fields.removeByName("last_name");
  users.fields.removeByName("first_name");
  users.fields.removeByName("patronymic");
  users.updateRule = "id = @request.auth.id";
  app.save(users);
})
