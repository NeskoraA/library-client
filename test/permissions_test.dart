import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/models/app_user.dart';
import 'package:library_app/state/permissions.dart';

void main() {
  test('читатель видит каталог и свои выдачи, но не редактирует', () {
    expect(roleCan(Role.reader, Permission.viewCatalog), isTrue);
    expect(roleCan(Role.reader, Permission.viewOwnLoans), isTrue);
    expect(roleCan(Role.reader, Permission.editCatalog), isFalse);
    expect(roleCan(Role.reader, Permission.manageLoans), isFalse);
  });

  test('библиотекарь управляет каталогом, читателями и выдачами', () {
    expect(roleCan(Role.librarian, Permission.editCatalog), isTrue);
    expect(roleCan(Role.librarian, Permission.manageReaders), isTrue);
    expect(roleCan(Role.librarian, Permission.manageLoans), isTrue);
  });

  test('библиотекарь не может физически удалять и восстанавливать', () {
    expect(roleCan(Role.librarian, Permission.hardDelete), isFalse);
    expect(roleCan(Role.librarian, Permission.restore), isFalse);
    expect(roleCan(Role.librarian, Permission.manageUsers), isFalse);
  });

  test('администратор управляет пользователями и видит статистику', () {
    expect(roleCan(Role.admin, Permission.manageUsers), isTrue);
    expect(roleCan(Role.admin, Permission.viewStats), isTrue);
    expect(roleCan(Role.admin, Permission.hardDelete), isTrue);
    expect(roleCan(Role.admin, Permission.restore), isTrue);
  });

  test('у каждой роли есть раздел, недоступный остальным', () {
    expect(roleCan(Role.reader, Permission.viewOwnLoans), isTrue);
    expect(roleCan(Role.librarian, Permission.viewOwnLoans), isFalse);
    expect(roleCan(Role.admin, Permission.viewOwnLoans), isFalse);

    expect(roleCan(Role.librarian, Permission.manageLoans), isTrue);
    expect(roleCan(Role.admin, Permission.manageLoans), isFalse);

    expect(roleCan(Role.admin, Permission.viewStats), isTrue);
    expect(roleCan(Role.librarian, Permission.viewStats), isFalse);
  });

  test('без входа ничего не разрешено', () {
    for (final p in Permission.values) {
      expect(roleCan(null, p), isFalse);
    }
  });

  test('неизвестная роль с сервера считается читателем', () {
    expect(Role.fromName('superuser'), Role.reader);
    expect(Role.fromName('admin'), Role.admin);
  });
}
