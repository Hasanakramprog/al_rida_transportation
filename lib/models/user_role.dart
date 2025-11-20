enum UserRole {
  admin,
  student,
  driver;

  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.student:
        return 'Student';
      case UserRole.driver:
        return 'Driver';
    }
  }

  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'student':
        return UserRole.student;
      case 'driver':
        return UserRole.driver;
      default:
        return UserRole.student; // Default role
    }
  }
}
