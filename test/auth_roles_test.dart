import 'package:flutter_test/flutter_test.dart';

import 'package:armory_last/models/role.dart';

import 'support/fake_auth.dart';

/// ПР5, оценка «5»: «тесты на логику разграничения прав — не менее пяти
/// проверок соответствия роли и доступности операции».
void main() {
  group('Role — иерархия уровней', () {
    test('buyer < seller < admin', () {
      expect(Role.buyer.level, lessThan(Role.seller.level));
      expect(Role.seller.level, lessThan(Role.admin.level));
    });

    test('fromWire восстанавливает роль по строке с сервера', () {
      expect(Role.fromWire('seller'), Role.seller);
      expect(Role.fromWire('admin'), Role.admin);
    });

    test('fromWire откатывается на buyer для неизвестного значения', () {
      // Сервер — источник истины по ролям; если когда-нибудь пришлют
      // значение, которого клиент не знает, показывать нужно наименьшие
      // права, а не падать и не молча выдавать что-то более привилегированное.
      expect(Role.fromWire('unknown-role'), Role.buyer);
    });
  });

  group('AuthNotifier.has — соответствие роли и доступности операции', () {
    test('покупатель не видит операций продавца и администратора', () async {
      final auth = await loggedInAs('buyer');
      expect(auth.has(Role.buyer), isTrue);
      expect(auth.has(Role.seller), isFalse);
      expect(auth.has(Role.admin), isFalse);
    });

    test(
      'продавец видит операции покупателя и продавца, но не администратора',
      () async {
        final auth = await loggedInAs('seller');
        expect(auth.has(Role.buyer), isTrue);
        expect(auth.has(Role.seller), isTrue);
        expect(auth.has(Role.admin), isFalse);
      },
    );

    test('администратор видит операции всех трёх ролей', () async {
      final auth = await loggedInAs('admin');
      expect(auth.has(Role.buyer), isTrue);
      expect(auth.has(Role.seller), isTrue);
      expect(auth.has(Role.admin), isTrue);
    });

    test('незалогиненный пользователь не имеет прав ни одной роли', () async {
      final auth = await loggedOut(); // login() ни разу не вызван
      expect(auth.has(Role.buyer), isFalse);
      expect(auth.has(Role.seller), isFalse);
      expect(auth.has(Role.admin), isFalse);
    });

    test(
      'вход как покупатель привязывает clientId — нужен для "своих" заказов',
      () async {
        final auth = await loggedInAs('buyer');
        expect(auth.user?.clientId, 'client1');
      },
    );
  });
}
