import 'package:flutter/foundation.dart';

import '../../core/errors/app_exception.dart';
import '../../data/models/promote_package.dart';
import '../../data/repositories/promote_repository.dart';
import '../base_view_model.dart';

class PromotePlansViewModel extends BaseViewModel {
  PromotePlansViewModel(this._repo) {
    load();
  }

  final PromoteRepository _repo;

  List<PromotePackage> _packages = const [];
  bool _listLoading = false;
  String? _listError;

  List<PromotePackage> get packages => _packages;
  bool get listLoading => _listLoading;
  String? get listError => _listError;

  Future<void> load() async {
    _listLoading = true;
    _listError = null;
    notify();
    try {
      _packages = await _repo.fetchPackages(activeOnly: false);
    } catch (e) {
      debugPrint('Load packages failed: $e');
      _listError = AppException.from(e).message;
    } finally {
      _listLoading = false;
      notify();
    }
  }

  Future<bool> save(PromotePackage package) async {
    final ok = await runAction(() => _repo.savePackage(package));
    if (ok) await load();
    return ok;
  }

  Future<bool> toggleActive(PromotePackage p) => save(
    PromotePackage(
      id: p.id,
      name: p.name,
      price: p.price,
      durationDays: p.durationDays,
      isActive: !p.isActive,
      sortOrder: p.sortOrder,
      description: p.description,
    ),
  );

  /// Returns true if deleted, false if deactivated instead, null on error.
  Future<bool?> delete(String id) async {
    final deleted = await guard(() => _repo.deleteOrDeactivatePackage(id));
    if (deleted != null) await load();
    return deleted;
  }
}
