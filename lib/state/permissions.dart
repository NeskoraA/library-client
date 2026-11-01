import '../models/app_user.dart';

enum Permission {
  viewCatalog,
  editCatalog,
  manageReaders,
  manageLoans,
  viewOwnLoans,
  hardDelete,
  restore,
  manageUsers,
  viewStats,
}

const rolePermissions = <Role, Set<Permission>>{
  Role.reader: {Permission.viewCatalog, Permission.viewOwnLoans},
  Role.librarian: {
    Permission.viewCatalog,
    Permission.editCatalog,
    Permission.manageReaders,
    Permission.manageLoans,
  },
  Role.admin: {
    Permission.viewCatalog,
    Permission.editCatalog,
    Permission.manageReaders,
    Permission.hardDelete,
    Permission.restore,
    Permission.manageUsers,
    Permission.viewStats,
  },
};

bool roleCan(Role? role, Permission permission) =>
    role != null && (rolePermissions[role]?.contains(permission) ?? false);
