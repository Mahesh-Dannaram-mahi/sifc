// lib/product_review/services/batch_rating_service.dart

import '../../models/recommended_product.dart';
import '../services/rating_service.dart';
import '../../services/storage_service.dart';

class BatchRatingService {
  /// Load ratings for multiple products at once
  static Future<void> loadRatingsForProducts(List<RecommendedProduct> products) async {
    final userId = await StorageService.getUserId();
    if (userId == null || userId.isEmpty) {
      return;
    }
    
    // Load ratings in parallel
    final futures = products.map((product) async {
      final ratingData = await RatingService.getProductRatingData(
        userId: userId,
        productId: product.id,
      );
      if (ratingData != null) {
        product.updateRatingData(ratingData);
      }
      return product;
    });
    
    await Future.wait(futures);
  }
  
  /// Load rating for a single product
  static Future<void> loadRatingForProduct(RecommendedProduct product) async {
    final userId = await StorageService.getUserId();
    if (userId == null || userId.isEmpty) {
      return;
    }
    
    final ratingData = await RatingService.getProductRatingData(
      userId: userId,
      productId: product.id,
    );
    if (ratingData != null) {
      product.updateRatingData(ratingData);
    }
  }
}