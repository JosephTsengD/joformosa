enum AuthProvider { guest, line }

class AppUser {
  const AppUser({
    required this.id,
    required this.provider,
    this.displayName,
    this.avatarUrl,
    this.lineUserId,
  });

  final String id;
  final AuthProvider provider;
  final String? displayName;
  final String? avatarUrl;
  final String? lineUserId;

  bool get isGuest => provider == AuthProvider.guest;
}
