import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:armory_last/screens/auth/login_screen.dart';
import 'package:armory_last/screens/home_screen.dart';
import 'package:armory_last/state/auth_notifier.dart';
import 'package:armory_last/state/load_status.dart';
import 'package:armory_last/widgets/status_view.dart';

import 'support/fake_auth.dart';

/// ПР6, оценка «5»: не менее пяти тестов виджетов, покрывающих отображение
/// состояния загрузки, пустого результата, ошибки с кнопкой повтора,
/// срабатывание валидации формы и скрытие недоступного элемента при
/// недостаточной роли.
void main() {
  Widget wrap(Widget child) => MaterialApp(home: child);

  group('StatusView — состояния списка', () {
    testWidgets('показывает индикатор загрузки', (tester) async {
      await tester.pumpWidget(
        wrap(
          StatusView(
            status: LoadStatus.loading,
            error: null,
            isEmpty: false,
            builder: (context) => const Text('Данные'),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Данные'), findsNothing);
    });

    testWidgets('показывает сообщение при пустом результате', (tester) async {
      await tester.pumpWidget(
        wrap(
          StatusView(
            status: LoadStatus.success,
            error: null,
            isEmpty: true,
            emptyMessage: 'Ничего не найдено',
            builder: (context) => const Text('Данные'),
          ),
        ),
      );

      expect(find.text('Ничего не найдено'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Данные'), findsNothing);
    });

    testWidgets(
      'показывает ошибку с кнопкой повтора и вызывает onRetry по нажатию',
      (tester) async {
        var retried = false;
        await tester.pumpWidget(
          wrap(
            StatusView(
              status: LoadStatus.error,
              error: 'Сервер недоступен',
              isEmpty: false,
              onRetry: () => retried = true,
              builder: (context) => const Text('Данные'),
            ),
          ),
        );

        expect(find.text('Сервер недоступен'), findsOneWidget);
        final retryButton = find.text('Повторить');
        expect(retryButton, findsOneWidget);

        await tester.tap(retryButton);
        await tester.pump();

        expect(retried, isTrue);
      },
    );
  });

  group('Валидация формы', () {
    testWidgets('пустая форма входа показывает "Обязательное поле"', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final auth = AuthNotifier(prefs, PocketBase('http://test.local'));

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthNotifier>.value(
            value: auth,
            child: const LoginScreen(),
          ),
        ),
      );

      await tester.tap(find.text('Войти'));
      await tester.pump();

      // Оба поля пустые — форма не должна уйти в сеть, а должна показать
      // ошибку валидации сразу под каждым полем.
      expect(find.text('Обязательное поле'), findsWidgets);
    });
  });

  group('Скрытие элементов по роли', () {
    testWidgets('покупатель не видит "Администрирование" и "Покупатели"', (
      tester,
    ) async {
      // testWidgets выполняет тело в зоне с фейковым временем — реальный
      // Future от http-транспорта (даже с поддельным MockClient) не долетает
      // до завершения сам по себе и виснет до тайм-аута фреймворка (10
      // минут). tester.runAsync() на время прогоняет колбэк в настоящей зоне.
      final auth = (await tester.runAsync(() => loggedInAs('buyer')))!;

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthNotifier>.value(
            value: auth,
            child: const HomeScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Администрирование'), findsNothing);
      expect(find.text('Покупатели'), findsNothing);
      // Каталог виден всем ролям.
      expect(find.text('Оружие'), findsOneWidget);
      // Реальная разница между ролями, а не декорация: у покупателя
      // отдельная подпись на той же карточке заказов.
      expect(find.text('Мои заказы'), findsOneWidget);
    });

    testWidgets('администратор видит "Администрирование" и "Покупатели"', (
      tester,
    ) async {
      final auth = (await tester.runAsync(() => loggedInAs('admin')))!;

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthNotifier>.value(
            value: auth,
            child: const HomeScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Администрирование'), findsOneWidget);
      expect(find.text('Покупатели'), findsOneWidget);
      expect(find.text('Заказы'), findsOneWidget);
    });
  });
}
