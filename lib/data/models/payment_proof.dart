import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';
import 'model_utils.dart';

/// `paymentProofs/{id}` — compressed JPEG stored as a Firestore Blob.
class PaymentProof {
  const PaymentProof({
    required this.id,
    required this.uid,
    required this.bytes,
    required this.mimeType,
    required this.sizeBytes,
    this.createdAt,
  });

  final String id;
  final String uid;
  final Uint8List bytes;
  final String mimeType;
  final int sizeBytes;
  final DateTime? createdAt;

  factory PaymentProof.fromDoc(Doc doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    final blob = d[FsKeys.bytes];
    return PaymentProof(
      id: doc.id,
      uid: d.str(FsKeys.uid),
      bytes: blob is Blob ? blob.bytes : Uint8List(0),
      mimeType: d.str(FsKeys.mimeType, AppConstants.proofMimeType),
      sizeBytes: d.integer(FsKeys.sizeBytes),
      createdAt: d.date(FsKeys.createdAt),
    );
  }

  static Map<String, dynamic> createMap(String uid, Uint8List bytes) => {
    FsKeys.uid: uid,
    FsKeys.bytes: Blob(bytes),
    FsKeys.mimeType: AppConstants.proofMimeType,
    FsKeys.sizeBytes: bytes.lengthInBytes,
    FsKeys.createdAt: FieldValue.serverTimestamp(),
  };
}
