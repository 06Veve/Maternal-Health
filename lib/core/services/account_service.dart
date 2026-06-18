import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum AccountRole { mother, partner }

class AccountService {
  AccountService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Future<String?> currentHouseholdId() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final profile = await _db.collection('users').doc(uid).get();
    return profile.data()?['householdId'] as String?;
  }

  Future<void> migrateCurrentUserIfNeeded() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final userRef = _db.collection('users').doc(user.uid);
    final snapshot = await userRef.get();
    final data = snapshot.data() ?? <String, dynamic>{};
    if (data['householdId'] != null) return;
    final initial = data['gestationalAgeWeeks'] as int? ?? 1;
    final reference =
        (data['gestationalReferenceDate'] as Timestamp?)?.toDate() ??
        DateTime.now();
    final legacyPregnancy = Map<String, dynamic>.from(
      data['pregnancy'] as Map? ?? {},
    );
    final lmp =
        (legacyPregnancy['lmpEstimated'] as Timestamp?)?.toDate() ??
        reference.subtract(Duration(days: initial * 7));
    final household = _db.collection('households').doc();
    final batch = _db.batch();
    batch.set(userRef, {
      'name':
          data['name'] ??
          user.displayName ??
          user.email?.split('@').first ??
          'Mother',
      'email': user.email,
      'role': 'mother',
      'householdId': household.id,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    batch.set(household, {
      'motherId': user.uid,
      'partnerId': null,
      'memberIds': [user.uid],
      'pregnancy': {
        'gestationalAgeWeeks': initial,
        'referenceDate': Timestamp.fromDate(reference),
        'lmpEstimated': Timestamp.fromDate(lmp),
        'dueDate': Timestamp.fromDate(lmp.add(const Duration(days: 280))),
      },
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
    await _migrateLegacyData(user.uid, household.id);
  }

  Future<void> _migrateLegacyData(String uid, String householdId) async {
    final migrations =
        <(String, String, Map<String, dynamic> Function(Map<String, dynamic>))>[
          ('events', 'events', (data) => data),
          ('emergencyContacts', 'emergencyContacts', (data) => data),
          (
            'kicks',
            'kickSessions',
            (data) => {
              ...data,
              'createdAt': data['timestamp'] ?? FieldValue.serverTimestamp(),
              'createdBy': uid,
            },
          ),
          (
            'symptoms',
            'healthLogs',
            (data) => {...data, 'type': 'symptoms', 'createdBy': uid},
          ),
        ];
    for (final migration in migrations) {
      final legacy = await _db
          .collection('users')
          .doc(uid)
          .collection(migration.$1)
          .limit(100)
          .get();
      if (legacy.docs.isEmpty) continue;
      final batch = _db.batch();
      for (final doc in legacy.docs) {
        final target = _db
            .collection('households')
            .doc(householdId)
            .collection(migration.$2)
            .doc(doc.id);
        batch.set(target, migration.$3(doc.data()));
      }
      await batch.commit();
    }
  }

  Future<void> createMotherProfile({
    required User user,
    required String name,
    required int gestationalWeeks,
  }) async {
    final household = _db.collection('households').doc();
    final now = DateTime.now();
    final lmp = now.subtract(Duration(days: gestationalWeeks * 7));
    final dueDate = lmp.add(const Duration(days: 280));
    final batch = _db.batch();

    batch.set(_db.collection('users').doc(user.uid), {
      'name': name.trim(),
      'email': user.email,
      'role': AccountRole.mother.name,
      'householdId': household.id,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(household, {
      'motherId': user.uid,
      'partnerId': null,
      'memberIds': [user.uid],
      'pregnancy': {
        'gestationalAgeWeeks': gestationalWeeks,
        'referenceDate': Timestamp.fromDate(now),
        'lmpEstimated': Timestamp.fromDate(lmp),
        'dueDate': Timestamp.fromDate(dueDate),
      },
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> createPartnerProfile({
    required User user,
    required String name,
    required String invitationCode,
  }) async {
    await _db.collection('users').doc(user.uid).set({
      'name': name.trim(),
      'email': user.email,
      'role': AccountRole.partner.name,
      'householdId': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await acceptPartnerInvite(invitationCode);
  }

  Future<String> createPartnerInvite() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final profile = await _db.collection('users').doc(uid).get();
    final householdId = profile.data()?['householdId'] as String?;
    if (profile.data()?['role'] != 'mother' || householdId == null) {
      throw StateError('Only a mother account can invite a partner.');
    }
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    final code = List.generate(
      10,
      (_) => alphabet[random.nextInt(alphabet.length)],
    ).join();
    final inviteRef = _db.collection('partnerInvites').doc(code);
    final householdRef = _db.collection('households').doc(householdId);
    final expiresAt = DateTime.now().add(const Duration(days: 7));
    await _db.runTransaction((transaction) async {
      final household = await transaction.get(householdRef);
      if (household.data()?['partnerId'] != null) {
        throw StateError('A partner is already linked.');
      }
      transaction.set(inviteRef, {
        'householdId': householdId,
        'motherId': uid,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(expiresAt),
      });
      transaction.update(householdRef, {
        'inviteCode': code,
        'inviteExpiresAt': Timestamp.fromDate(expiresAt),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
    return code;
  }

  Future<void> acceptPartnerInvite(String invitationCode) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final code = invitationCode.trim().toUpperCase();
    final inviteRef = _db.collection('partnerInvites').doc(code);
    final userRef = _db.collection('users').doc(uid);
    await _db.runTransaction((transaction) async {
      final invite = await transaction.get(inviteRef);
      final inviteData = invite.data();
      if (inviteData == null || inviteData['status'] != 'pending') {
        throw StateError('Invitation invalid or already used.');
      }
      final expiresAt = inviteData['expiresAt'] as Timestamp?;
      if (expiresAt == null || expiresAt.toDate().isBefore(DateTime.now())) {
        throw StateError('Invitation expired.');
      }
      final householdId = inviteData['householdId'] as String;
      final householdRef = _db.collection('households').doc(householdId);
      transaction.update(userRef, {
        'role': 'partner',
        'householdId': householdId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.update(householdRef, {
        'partnerId': uid,
        'memberIds': FieldValue.arrayUnion([uid]),
        'inviteCode': FieldValue.delete(),
        'inviteExpiresAt': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.update(inviteRef, {
        'status': 'accepted',
        'partnerId': uid,
        'acceptedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
