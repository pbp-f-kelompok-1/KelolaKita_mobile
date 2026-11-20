class AccountProfile {
  const AccountProfile({
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phoneNumber = '',
    this.address = '',
    this.avatarUrl = '',
    this.role = 'Pengguna',
    this.points = 0,
    this.updatedAt = '',
  });

  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String address;
  final String avatarUrl;
  final String role;
  final int points;
  final String updatedAt;

  String get fullName => '$firstName $lastName'.trim().isEmpty
      ? username
      : '$firstName $lastName'.trim();

  Map<String, String> get editableFields => {
    'first_name': firstName,
    'last_name': lastName,
    'email': email,
    'phone_number': phoneNumber,
    'address': address,
    'avatar_url': avatarUrl,
  };
}

class AccountException implements Exception {
  const AccountException(this.message, {this.expired = false});
  final String message;
  final bool expired;

  @override
  String toString() => message;
}
