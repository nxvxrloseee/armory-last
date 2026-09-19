migrate((app) => {
  const users = app.findCollectionByNameOrId("users");
  const manufacturers = app.findCollectionByNameOrId("manufacturers");
  const categories = app.findCollectionByNameOrId("categories");
  const designers = app.findCollectionByNameOrId("designers");
  const stores = app.findCollectionByNameOrId("stores");
  const weapons = app.findCollectionByNameOrId("weapons");
  const clients = app.findCollectionByNameOrId("clients");
  const licenses = app.findCollectionByNameOrId("licenses");
  const orders = app.findCollectionByNameOrId("orders");

  const buyerUser = new Record(users, {
    email: "pokupatel@armory.test",
    password: "Buyer123!",
    passwordConfirm: "Buyer123!",
    emailVisibility: true,
    verified: true,
    role: "buyer",
    last_name: "Покупателев", first_name: "Иван", patronymic: "Иванович",
  });
  app.save(buyerUser);

  const sellerUser = new Record(users, {
    email: "prodavec@armory.test",
    password: "Seller123!",
    passwordConfirm: "Seller123!",
    emailVisibility: true,
    verified: true,
    role: "seller",
    last_name: "Продавцова", first_name: "Светлана", patronymic: "Андреевна",
  });
  app.save(sellerUser);

  const adminUser = new Record(users, {
    email: "admin@armory.test",
    password: "Admin123!",
    passwordConfirm: "Admin123!",
    emailVisibility: true,
    verified: true,
    role: "admin",
    last_name: "Системный", first_name: "Админ",
  });
  app.save(adminUser);

  const manu1 = new Record(manufacturers, { name: "Ижмаш", country: "Россия", founded: 1807 });
  app.save(manu1);
  const manu2 = new Record(manufacturers, { name: "Kalashnikov Concern", country: "Россия", founded: 2013 });
  app.save(manu2);
  const manu3 = new Record(manufacturers, { name: "Baikal", country: "Россия", founded: 1942 });
  app.save(manu3);

  const catRifle = new Record(categories, { name: "Нарезное", license_type: "rifle" });
  app.save(catRifle);
  const catShotgun = new Record(categories, { name: "Гладкоствольное", license_type: "shotgun" });
  app.save(catShotgun);
  const catPistol = new Record(categories, { name: "Пистолет", license_type: "pistol" });
  app.save(catPistol);
  const catHunting = new Record(categories, { name: "Охотничье", license_type: "shotgun" });
  app.save(catHunting);

  const des1 = new Record(designers, { full_name: "М.Т. Калашников", country: "Россия", active_since: 1938 });
  app.save(des1);
  const des2 = new Record(designers, { full_name: "Е.Ф. Драгунов", country: "Россия", active_since: 1950 });
  app.save(des2);

  const store1 = new Record(stores, { name: "Магазин на Ленина", address: "г. Тверь, ул. Ленина, 10" });
  app.save(store1);
  const store2 = new Record(stores, { name: "Магазин на Советской", address: "г. Тверь, ул. Советская, 25" });
  app.save(store2);

  const w1 = new Record(weapons, {
    name: "АК-74", sku: "AK74-001", manufacturer: manu2.id,
    categories: [catRifle.id], designers: [des1.id],
    caliber: "5.45x39", year: 1974, price: 85000,
    stock_total: 10, stock_available: 10,
  });
  app.save(w1);

  const w2 = new Record(weapons, {
    name: "СВД", sku: "SVD-001", manufacturer: manu1.id,
    categories: [catRifle.id], designers: [des2.id],
    caliber: "7.62x54R", year: 1963, price: 150000,
    stock_total: 4, stock_available: 4,
  });
  app.save(w2);

  const w3 = new Record(weapons, {
    name: "МР-155", sku: "MR155-001", manufacturer: manu3.id,
    categories: [catShotgun.id, catHunting.id], designers: [],
    caliber: "12/76", year: 2010, price: 60000,
    stock_total: 15, stock_available: 15,
  });
  app.save(w3);

  const client1 = new Record(clients, {
    user: buyerUser.id, phone: "+7 900 000-00-00",
  });
  app.save(client1);

  const license1 = new Record(licenses, {
    client: client1.id, number: "ЛОа №00123456",
    type: "rifle", issued_at: "2024-01-15 00:00:00.000Z",
    expires_at: "2029-01-15 00:00:00.000Z",
  });
  app.save(license1);

  const order1 = new Record(orders, {
    client: client1.id, weapon: w1.id, store: store1.id, status: "ordered",
  });
  app.save(order1);
}, (app) => {
  for (const name of ["orders", "licenses", "clients", "weapons", "stores", "designers", "categories", "manufacturers"]) {
    const collection = app.findCollectionByNameOrId(name);
    const records = app.findRecordsByFilter(collection.id, "", "-created", 200, 0);
    for (const r of records) app.delete(r);
  }
  for (const email of ["pokupatel@armory.test", "prodavec@armory.test", "admin@armory.test"]) {
    const u = app.findAuthRecordByEmail("users", email);
    if (u) app.delete(u);
  }
})
