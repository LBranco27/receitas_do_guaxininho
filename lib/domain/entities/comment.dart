class Comment {
  final String id;
  final int recipeId;
  final String userId;
  final String text;
  final DateTime createdAt;
  final String? userName;
  final String? userAvatarUrl;

  Comment({
    required this.id,
    required this.recipeId,
    required this.userId,
    required this.text,
    required this.createdAt,
    this.userName,
    this.userAvatarUrl,
  });
}
