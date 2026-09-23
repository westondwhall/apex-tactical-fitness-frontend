class UserProfile {
  final String username;

  UserProfile({required this.username});

  factory UserProfile.fromJson(Map json) {
    return UserProfile(
      // Checks all standard field names returned by the backend
      username: json['full_name'] ?? 
                json['name'] ?? 
                json['username'] ?? 
                json['email'] ?? 
                'Unknown User',
    );
  }
}