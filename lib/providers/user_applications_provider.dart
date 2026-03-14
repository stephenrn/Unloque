import 'package:flutter/foundation.dart';
import 'package:unloque/services/applications/application_data_service.dart';

class UserApplicationsProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _applications = const [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<Map<String, dynamic>> get applications =>
      List<Map<String, dynamic>>.unmodifiable(_applications);

  List<Map<String, dynamic>> applicationsWithStatus(String status) {
    if (status.toLowerCase() == 'all') return applications;
    return applications
        .where((app) =>
            (app['status'] ?? '').toString().toLowerCase() ==
            status.toLowerCase())
        .toList(growable: false);
  }

  Future<void> loadAll({bool forceRefresh = false}) async {
    if (_isLoading) return;
    if (!forceRefresh && _applications.isNotEmpty) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final apps = await ApplicationDataService.getUserApplications();
      _applications = apps;
    } catch (e) {
      _errorMessage = e.toString();
      _applications = const [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> fetchForStatus(
    String status, {
    bool forceRefresh = false,
  }) async {
    await loadAll(forceRefresh: forceRefresh);
    return applicationsWithStatus(status);
  }

  void clear() {
    _applications = const [];
    _errorMessage = null;
    notifyListeners();
  }
}
