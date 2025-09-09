// lib/domain/entities/review.dart

class Review {
  final String id; // UUID
  final int recipeId; // Foreign key to Recipe's ID
  final String userId; // Foreign key to User's ID
  final int rating; // e.g., 1 to 5
  final String? text; // Optional review text
  final DateTime createdAt;
  final String? userName; // Denormalized from profiles table
  final String? userAvatarUrl; // Denormalized from profiles table

  Review({
    required this.id,
    required this.recipeId,
    required this.userId,
    required this.rating,
    this.text,
    required this.createdAt,
    this.userName,
    this.userAvatarUrl,
  });

  // Optional: Add fromJson/toJson if you plan to use them directly
  // For now, mapping will happen in the data source.

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Review && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  Review copyWith({
    String? id,
    int? recipeId,
    String? userId,
    int? rating,
    String? text,
    DateTime? createdAt,
    String? userName,
    String? userAvatarUrl,
    bool allowNullText = false, // Helper to explicitly set text to null
  }) {
    return Review(
      id: id ?? this.id,
      recipeId: recipeId ?? this.recipeId,
      userId: userId ?? this.userId,
      rating: rating ?? this.rating,
      text: allowNullText ? text : (text ?? this.text),
      createdAt: createdAt ?? this.createdAt,
      userName: userName ?? this.userName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
    );
  }
}
