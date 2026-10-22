import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';
import '../models/app_settings.dart';
import '../models/faq_item.dart';
import 'page_result.dart';

abstract class SettingsRepository {
  /// Live `settings/app`; emits null when the doc has not been created yet.
  Stream<AppSettings?> watchSettings();
  Future<AppSettings?> fetchSettings();
  Future<void> saveSettings(AppSettings settings);

  /// Writes default settings and sample promote packages (first run only).
  Future<void> createDefaults();

  Future<List<FaqItem>> fetchFaqs({bool activeOnly = true});
  Future<void> saveFaq(FaqItem faq);
  Future<void> deleteFaq(String id);
}

class FirestoreSettingsRepository implements SettingsRepository {
  FirestoreSettingsRepository(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> get _doc => _db.collection(FsCol.settings).doc(FsCol.settingsDoc);

  @override
  Stream<AppSettings?> watchSettings() => _doc.snapshots().map((s) => s.exists ? AppSettings.fromMap(s.data()!) : null);

  @override
  Future<AppSettings?> fetchSettings() async {
    final s = await _doc.get();
    return s.exists ? AppSettings.fromMap(s.data()!) : null;
  }

  @override
  Future<void> saveSettings(AppSettings settings) => _doc.set(settings.toMap()).withWriteTimeout();

  @override
  Future<void> createDefaults() async {
    await _db.runTransaction((tx) async {
      final existing = await tx.get(_doc);
      if (existing.exists) return;
      tx.set(_doc, const AppSettings().toMap());
      final packages = _db.collection(FsCol.promotePackages);
      const samples = [(500, 1), (1000, 2), (1500, 3)];
      for (var i = 0; i < samples.length; i++) {
        final (price, days) = samples[i];
        tx.set(packages.doc(), {
          FsKeys.name: days == 1 ? '1 Day' : '$days Days',
          FsKeys.price: price,
          FsKeys.durationDays: days,
          FsKeys.isActive: true,
          FsKeys.sortOrder: i,
          FsKeys.description: null,
        });
      }
    }).withWriteTimeout();
  }

  @override
  Future<List<FaqItem>> fetchFaqs({bool activeOnly = true}) async {
    Query<Map<String, dynamic>> q = _db.collection(FsCol.faqs);
    if (activeOnly) q = q.where(FsKeys.isActive, isEqualTo: true);
    final snap = await q.orderBy(FsKeys.sortOrder).limit(100).get();
    return snap.docs.map(FaqItem.fromDoc).toList();
  }

  @override
  Future<void> saveFaq(FaqItem faq) {
    final col = _db.collection(FsCol.faqs);
    final ref = faq.id.isEmpty ? col.doc() : col.doc(faq.id);
    return ref.set(faq.toMap()).withWriteTimeout();
  }

  @override
  Future<void> deleteFaq(String id) => _db.collection(FsCol.faqs).doc(id).delete().withWriteTimeout();
}
