/// Follow relationship between two users.
/// status: 'accepted' (instant for public profiles) or 'pending' (for private profiles)
class Follow {
  final String id;
  final String followerId;
  final String followingId;
  final String status; // 'pending' | 'accepted'
  final DateTime createdAt;

  Follow({
    required this.id,
    required this.followerId,
    required this.followingId,
    this.status = 'pending',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isAccepted => status == 'accepted';
  bool get isPending => status == 'pending';

  factory Follow.fromMap(Map<String, dynamic> d) {
    return Follow(
      id: d['id'].toString(),
      followerId: d['follower_id'] ?? '',
      followingId: d['following_id'] ?? '',
      status: d['status'] ?? 'pending',
      createdAt: d['created_at'] != null
          ? DateTime.parse(d['created_at'])
          : DateTime.now(),
    );
  }
}
