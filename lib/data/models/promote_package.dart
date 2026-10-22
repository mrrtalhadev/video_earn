import '../../core/constants/app_constants.dart';
import 'model_utils.dart';

class PromotePackage {
  const PromotePackage({
    required this.id,
    required this.name,
    required this.price,
    required this.durationDays,
    required this.isActive,
    this.sortOrder = 0,
    this.description,
  });

  final String id;
  final String name;
  final int price;
  final int durationDays;
  final bool isActive;
  final int sortOrder;
  final String? description;

  factory PromotePackage.fromDoc(Doc doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return PromotePackage(
      id: doc.id,
      name: d.str(FsKeys.name),
      price: d.integer(FsKeys.price),
      durationDays: d.integer(FsKeys.durationDays, 1),
      isActive: d.boolean(FsKeys.isActive),
      sortOrder: d.integer(FsKeys.sortOrder),
      description: d.strOrNull(FsKeys.description),
    );
  }

  Map<String, dynamic> toMap() => {
    FsKeys.name: name,
    FsKeys.price: price,
    FsKeys.durationDays: durationDays,
    FsKeys.isActive: isActive,
    FsKeys.sortOrder: sortOrder,
    FsKeys.description: description,
  };
}
