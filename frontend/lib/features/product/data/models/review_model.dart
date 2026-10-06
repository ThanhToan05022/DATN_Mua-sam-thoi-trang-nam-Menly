class Review {
  final String id;
  final String userId;
  final String productId;
  final int rating;
  final String? comment;
  final String createdAt;
  final String userName;

  Review({
    required this.id,
    required this.userId,
    required this.productId,
    required this.rating,
    this.comment,
    required this.createdAt,
    required this.userName,
  });

  factory Review.fromJson(Map<String, dynamic> j) {
    String name = 'Khách hàng';
    if (j['user'] is Map) {
      name = j['user']['name'] ?? j['user']['full_name'] ?? j['user']['email'] ?? 'Khách hàng';
    } else if (j['profiles'] is Map) {
      name = j['profiles']['full_name'] ?? j['profiles']['name'] ?? j['profiles']['email'] ?? 'Khách hàng';
    }
    return Review(
      id: j['id'] ?? '',
      userId: j['userId'] ?? j['user_id'] ?? '',
      productId: j['productId'] ?? j['product_id'] ?? '',
      rating: j['rating'] is num ? (j['rating'] as num).toInt() : 5,
      comment: j['comment'],
      createdAt: j['createdAt'] ?? j['created_at'] ?? '',
      userName: name,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'productId': productId,
    'rating': rating,
    'comment': comment,
    'createdAt': createdAt,
    'userName': userName,
  };
}
