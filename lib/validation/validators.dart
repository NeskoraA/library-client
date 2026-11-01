typedef Validator = String? Function(String? value);

Validator combine(List<Validator> validators) => (value) {
  for (final v in validators) {
    final error = v(value);
    if (error != null) return error;
  }
  return null;
};

String? requiredField(String? value) =>
    (value == null || value.trim().isEmpty) ? 'Поле обязательно' : null;

Validator maxLength(int max) =>
    (value) =>
        (value != null && value.trim().length > max)
            ? 'Не более $max символов'
            : null;

Validator minLength(int min) =>
    (value) =>
        (value != null && value.trim().isNotEmpty && value.trim().length < min)
            ? 'Не менее $min символов'
            : null;

String? integer(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  return int.tryParse(value.trim()) == null ? 'Введите целое число' : null;
}

Validator intRange(int min, int max) => (value) {
  final n = int.tryParse(value?.trim() ?? '');
  if (n == null) return null;
  return (n < min || n > max) ? 'Допустимо от $min до $max' : null;
};

String? positive(String? value) {
  final n = int.tryParse(value?.trim() ?? '');
  if (n == null) return null;
  return n <= 0 ? 'Значение должно быть больше нуля' : null;
}

final _emailRe = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');

String? email(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  return _emailRe.hasMatch(value.trim()) ? null : 'Неверный формат почты';
}

final _phoneRe = RegExp(r'^\+7\d{10}$');

String? phone(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final compact = value.replaceAll(RegExp(r'[\s()-]'), '');
  return _phoneRe.hasMatch(compact) ? null : 'Формат: +7 и 10 цифр';
}

String? isbn(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final digits = value.replaceAll('-', '').trim();
  if (!RegExp(r'^\d{13}$').hasMatch(digits)) {
    return 'ISBN должен содержать 13 цифр';
  }
  if (!digits.startsWith('978') && !digits.startsWith('979')) {
    return 'ISBN начинается с 978 или 979';
  }
  return null;
}

final _personRe = RegExp(r"^[A-Za-zА-Яа-яЁё\s.'-]+$");

String? personName(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  return _personRe.hasMatch(value.trim())
      ? null
      : 'Допустимы буквы, пробел, точка и дефис';
}

final _lettersRe = RegExp(r"^[A-Za-zА-Яа-яЁё\s'-]+$");

String? letters(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  return _lettersRe.hasMatch(value.trim()) ? null : 'Допустимы только буквы';
}

final _cardRe = RegExp(r'^ЧБ-\d{6}$');

String? cardNumber(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  return _cardRe.hasMatch(value.trim()) ? null : 'Формат: ЧБ-123456';
}

DateTime? parseDate(String? value) {
  final m = RegExp(
    r'^(\d{2})\.(\d{2})\.(\d{4})$',
  ).firstMatch(value?.trim() ?? '');
  if (m == null) return null;
  final day = int.parse(m[1]!),
      month = int.parse(m[2]!),
      year = int.parse(m[3]!);
  final date = DateTime(year, month, day);
  return (date.day == day && date.month == month) ? date : null;
}

String formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';

String? date(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  return parseDate(value) == null ? 'Дата в формате ДД.ММ.ГГГГ' : null;
}

String? requiredChoice(Object? value) =>
    value == null ? 'Выберите значение' : null;

String? Function(List<int>?) minSelected(int min, String message) =>
    (value) => (value == null || value.length < min) ? message : null;

int get currentYear => DateTime.now().year;

String? passwordLength(String? value) =>
    (value ?? '').length < 8 ? 'Не короче восьми символов' : null;

String? passwordDigit(String? value) =>
    RegExp(r'\d').hasMatch(value ?? '') ? null : 'Нужна хотя бы одна цифра';

String? passwordSpecial(String? value) =>
    RegExp(r'[^A-Za-zА-Яа-яЁё0-9]').hasMatch(value ?? '')
        ? null
        : 'Нужен хотя бы один специальный символ';
