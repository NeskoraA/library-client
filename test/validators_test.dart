import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/models/author.dart';
import 'package:library_app/models/book.dart';
import 'package:library_app/models/loan.dart';
import 'package:library_app/models/reader.dart';
import 'package:library_app/validation/validators.dart';

void main() {
  group('Валидаторы', () {
    test('обязательное поле отклоняет пустую строку и пробелы', () {
      expect(requiredField(''), isNotNull);
      expect(requiredField('   '), isNotNull);
      expect(requiredField('Война и мир'), isNull);
    });

    test('длина строки ограничена', () {
      expect(maxLength(3)('abcd'), isNotNull);
      expect(maxLength(3)('abc'), isNull);
    });

    test('число проверяется по диапазону', () {
      expect(intRange(1, 10)('0'), isNotNull);
      expect(intRange(1, 10)('5'), isNull);
      expect(integer('abc'), isNotNull);
    });

    test('почта проверяется по формату', () {
      expect(email('ivanov'), isNotNull);
      expect(email('ivanov@example.com'), isNull);
    });

    test('ISBN содержит 13 цифр и начинается с 978 или 979', () {
      expect(isbn('123'), isNotNull);
      expect(isbn('123-4-56-789012-3'), isNotNull);
      expect(isbn('978-5-17-118366-4'), isNull);
    });

    test('телефон допускает пробелы и дефисы', () {
      expect(phone('+7 900 100-10-01'), isNull);
      expect(phone('89001001001'), isNotNull);
    });

    test('пароль проверяется на длину, цифру и спецсимвол', () {
      expect(passwordLength('short'), isNotNull);
      expect(passwordDigit('password'), isNotNull);
      expect(passwordSpecial('Passw0rd'), isNotNull);
      expect(passwordSpecial('Passw0rd!'), isNull);
    });

    test('combine возвращает первую ошибку', () {
      final v = combine([requiredField, maxLength(2)]);
      expect(v(''), 'Поле обязательно');
      expect(v('abc'), 'Не более 2 символов');
      expect(v('ab'), isNull);
    });

    test('дата разбирается и отвергает несуществующий день', () {
      expect(parseDate('01.02.2026'), DateTime(2026, 2, 1));
      expect(parseDate('31.02.2026'), isNull);
    });
  });

  group('Разбор моделей', () {
    test('книга без полей не приводит к исключению', () {
      final book = Book.fromJson({'id': 1});
      expect(book.title, '');
      expect(book.authorIds, isEmpty);
      expect(book.isDeleted, isFalse);
    });

    test('автор с неверным типом поля получает значение по умолчанию', () {
      final author = Author.fromJson({'id': 1, 'birthYear': 'нет'});
      expect(author.birthYear, 0);
    });

    test('читатель без билета разбирается', () {
      final reader = Reader.fromJson({'id': 1, 'fullName': 'Иванов И. И.'});
      expect(reader.card, isNull);
    });

    test('выдача разбирает вложенные объекты и состояние', () {
      final loan = Loan.fromJson({
        'id': 1,
        'reader': {'id': 2, 'fullName': 'Смирнов П. А.'},
        'book': {'id': 3, 'title': '1984'},
        'status': 'overdue',
      });
      expect(loan.readerId, 2);
      expect(loan.bookTitle, '1984');
      expect(loan.statusLabel, 'просрочена');
    });
  });
}
