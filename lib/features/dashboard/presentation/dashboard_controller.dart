import 'package:flutter/foundation.dart';

import '../domain/dashboard.dart';

class DashboardController extends ChangeNotifier {
  DashboardController({
    required GetDashboardMetricsUseCase getDashboardMetricsUseCase,
  }) : _getDashboardMetricsUseCase = getDashboardMetricsUseCase;

  final GetDashboardMetricsUseCase _getDashboardMetricsUseCase;

  DashboardMetrics? _metrics;
  bool _isLoading = false;
  String? _errorMessage;

  DashboardMetrics? get metrics => _metrics;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadMetrics() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _metrics = await _getDashboardMetricsUseCase();
    } catch (error) {
      _errorMessage = _humanizeError(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _humanizeError(Object error) {
    if (error is StateError) {
      return error.message;
    }
    return 'Nao foi possivel montar o dashboard.';
  }
}
