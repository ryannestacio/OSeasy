part of 'service_orders_page.dart';

extension _ServiceOrdersPageHelpers on _ServiceOrdersPageState {
  bool _isClosedStatus(ServiceOrderStatus status) {
    return status == ServiceOrderStatus.delivered ||
        status == ServiceOrderStatus.canceled;
  }

  double _parseDecimal(String raw) {
    try {
      return AppFormatters.parseDecimal(raw);
    } catch (_) {
      return 0;
    }
  }

  void _showMessage(String message, {bool error = false}) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppPalette.black : AppPalette.navy,
      ),
    );
  }

  String _humanizeError(Object error) {
    if (error is StateError) {
      return error.message;
    }
    return 'Nao foi possivel concluir a operacao.';
  }
}
