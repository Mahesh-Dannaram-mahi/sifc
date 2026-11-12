// lib/models/product_rating_data.dart
class ProductRatingData {
  final bool success;
  final String userId;
  final String productId;
  final double? rating;
  final bool liked;
  final double averageRating;
  final int totalRatings;
  final int totalLikes;

  ProductRatingData({
    required this.success,
    required this.userId,
    required this.productId,
    this.rating,
    required this.liked,
    required this.averageRating,
    required this.totalRatings,
    required this.totalLikes,
  });

  factory ProductRatingData.fromJson(Map<String, dynamic> json) {
    return ProductRatingData(
      success: json['success'] ?? false,
      userId: json['user_id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      rating: json['rating'] != null 
          ? (json['rating'] is int 
              ? (json['rating'] as int).toDouble() 
              : json['rating'].toDouble()) 
          : null,
      liked: json['liked'] ?? false,
      averageRating: (json['average_rating'] ?? 0).toDouble(),
      totalRatings: json['total_ratings'] ?? 0,
      totalLikes: json['total_likes'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'user_id': userId,
      'product_id': productId,
      'rating': rating,
      'liked': liked,
      'average_rating': averageRating,
      'total_ratings': totalRatings,
      'total_likes': totalLikes,
    };
  }

  ProductRatingData copyWith({
    bool? success,
    String? userId,
    String? productId,
    double? rating,
    bool? liked,
    double? averageRating,
    int? totalRatings,
    int? totalLikes,
  }) {
    return ProductRatingData(
      success: success ?? this.success,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      rating: rating ?? this.rating,
      liked: liked ?? this.liked,
      averageRating: averageRating ?? this.averageRating,
      totalRatings: totalRatings ?? this.totalRatings,
      totalLikes: totalLikes ?? this.totalLikes,
    );
  }
}