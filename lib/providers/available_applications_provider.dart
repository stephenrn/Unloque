import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:unloque/services/applications/available_applications_service.dart';

class AvailableApplicationsProvider extends ChangeNotifier {
  bool _disposed = false;

  final List<Map<String, dynamic>> _allApplications = [];
  final Map<String, List<Map<String, dynamic>>> _applicationsByCategory = {};
  final Set<String> _loadingCategories = {};

  bool _isLoadingAll = false;
  bool _isSearching = false;
  String? _errorMessage;

  bool get isLoadingAll => _isLoadingAll;
  bool get isSearching => _isSearching;
  String? get errorMessage => _errorMessage;

  List<Map<String, dynamic>> get allApplications =>
      List<Map<String, dynamic>>.unmodifiable(_allApplications);

  List<Map<String, dynamic>> applicationsForCategory(String category) {
    return List<Map<String, dynamic>>.unmodifiable(
      _applicationsByCategory[category] ?? const [],
    );
  }

  bool isCategoryLoading(String category) =>
      _loadingCategories.contains(category);

  void _notifyListenersSafe() {
    if (_disposed) return;

    final phase = SchedulerBinding.instance.schedulerPhase;
    final isBuilding = phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks;

    if (isBuilding) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (_disposed) return;
        notifyListeners();
      });
      return;
    }

    notifyListeners();
  }

  void clearCache() {
    AvailableApplicationsService.clearCache();
    _allApplications.clear();
    _applicationsByCategory.clear();
    _errorMessage = null;
    _notifyListenersSafe();
  }

  Future<void> loadAll({bool forceRefresh = false}) async {
    if (_isLoadingAll) return;
    if (!forceRefresh && _allApplications.isNotEmpty) return;

    _isLoadingAll = true;
    _errorMessage = null;
    _notifyListenersSafe();

    try {
      final apps = await AvailableApplicationsService.getAllApplications();
      _allApplications
        ..clear()
        ..addAll(apps);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoadingAll = false;
      _notifyListenersSafe();
    }
  }

  Future<void> loadCategory(String category, {bool forceRefresh = false}) async {
    if (_loadingCategories.contains(category)) return;
    if (!forceRefresh && _applicationsByCategory.containsKey(category)) return;

    _loadingCategories.add(category);
    _errorMessage = null;
    _notifyListenersSafe();

    try {
      final apps = await AvailableApplicationsService.getApplicationsByCategory(category);
      _applicationsByCategory[category] = apps;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _loadingCategories.remove(category);
      _notifyListenersSafe();
    }
  }

  Future<List<Map<String, dynamic>>> searchPrograms(String query) async {
    if (_isSearching) return const [];

    _isSearching = true;
    _errorMessage = null;
    _notifyListenersSafe();

    try {
      return await AvailableApplicationsService.searchPrograms(query);
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isSearching = false;
      _notifyListenersSafe();
    }
  }

  Future<Map<String, dynamic>> getApplicationById(String programId) {
    return AvailableApplicationsService.getApplicationById(programId);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
