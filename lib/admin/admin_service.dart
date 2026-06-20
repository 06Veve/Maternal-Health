import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminMetrics {
  const AdminMetrics({
    required this.users,
    required this.mothers,
    required this.partners,
    required this.households,
    required this.posts,
  });

  final int users;
  final int mothers;
  final int partners;
  final int households;
  final int posts;
}

class AdminService {
  AdminService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _db = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  User? get currentUser => _auth.currentUser;

  Future<bool> isCurrentUserAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final admin = await _db.collection('admins').doc(user.uid).get();
    if (admin.exists) {
      return admin.data()?['active'] == true;
    }

    // Compatibility with the admin profile already used by the old project.
    final profile = await _db.collection('users').doc(user.uid).get();
    final data = profile.data();
    return data?['role'] == 'admin' && data?['is_active'] != false;
  }

  Future<AdminMetrics> loadMetrics() async {
    final results = await Future.wait([
      _db.collection('users').count().get(),
      _db.collection('users').where('role', isEqualTo: 'mother').count().get(),
      _db.collection('users').where('role', isEqualTo: 'partner').count().get(),
      _db.collection('households').count().get(),
      _db.collection('posts').count().get(),
    ]);
    return AdminMetrics(
      users: results[0].count ?? 0,
      mothers: results[1].count ?? 0,
      partners: results[2].count ?? 0,
      households: results[3].count ?? 0,
      posts: results[4].count ?? 0,
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> usersStream() =>
      _db.collection('users').limit(200).snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> householdsStream() =>
      _db.collection('households').limit(200).snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> postsStream() =>
      _db.collection('posts').limit(200).snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> repliesStream(String postId) =>
      _db
          .collection('posts')
          .doc(postId)
          .collection('replies')
          .orderBy('createdAt', descending: true)
          .limit(200)
          .snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> auditStream() => _db
      .collection('auditLogs')
      .orderBy('createdAt', descending: true)
      .limit(200)
      .snapshots();

  Future<void> deletePost({
    required String postId,
    required String reason,
  }) async {
    final post = _db.collection('posts').doc(postId);
    await _deleteCollection(post.collection('likes'));
    await _deleteCollection(post.collection('replies'));

    final batch = _db.batch();
    batch.delete(post);
    _addAudit(
      batch,
      action: 'delete_post',
      targetType: 'post',
      targetId: postId,
      reason: reason,
    );
    await batch.commit();
  }

  Future<void> deleteReply({
    required String postId,
    required String replyId,
    required String reason,
  }) async {
    final batch = _db.batch();
    batch.delete(
      _db.collection('posts').doc(postId).collection('replies').doc(replyId),
    );
    _addAudit(
      batch,
      action: 'delete_reply',
      targetType: 'reply',
      targetId: replyId,
      reason: reason,
      metadata: {'postId': postId},
    );
    await batch.commit();
  }

  Future<void> _deleteCollection(
    CollectionReference<Map<String, dynamic>> collection,
  ) async {
    while (true) {
      final documents = await collection.limit(200).get();
      if (documents.docs.isEmpty) return;
      final batch = _db.batch();
      for (final document in documents.docs) {
        batch.delete(document.reference);
      }
      await batch.commit();
    }
  }

  void _addAudit(
    WriteBatch batch, {
    required String action,
    required String targetType,
    required String targetId,
    required String reason,
    Map<String, dynamic>? metadata,
  }) {
    final user = _auth.currentUser!;
    final audit = _db.collection('auditLogs').doc();
    batch.set(audit, {
      'adminId': user.uid,
      'adminEmail': user.email,
      'action': action,
      'targetType': targetType,
      'targetId': targetId,
      'reason': reason.trim(),
      if (metadata != null) 'metadata': metadata,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> signOut() => _auth.signOut();
}
