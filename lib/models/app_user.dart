import 'entity.dart';

enum Role {
  reader('Читатель'),
  librarian('Библиотекарь'),
  admin('Администратор');

  final String label;
  const Role(this.label);

  static Role fromName(String? name) =>
      Role.values.where((r) => r.name == name).firstOrNull ?? Role.reader;
}

class AppUser {
  final int id;
  final String username;
  final String fullName;
  final String email;
  final Role role;
  final int? readerId;

  const AppUser({
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
    this.email = '',
    this.readerId,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: readInt(json['id']),
    username: readString(json['username']),
    fullName: readString(json['fullName']),
    email: readString(json['email']),
    role: Role.fromName(readString(json['role'])),
    readerId: json['readerId'] == null ? null : readInt(json['readerId']),
  );
}
