import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/formatters.dart';
import '../../items/domain/items.dart';
import '../domain/service_orders.dart';

part 'service_order_customer_dialog.dart';
part 'service_order_customer_lookup_dialog.dart';
part 'service_order_equipment_dialog.dart';
part 'service_order_technician_dialog.dart';
part 'service_order_service_line_dialog.dart';
part 'service_order_part_dialog.dart';
part 'stock_item_lookup_dialog.dart';

double _responsiveDialogWidth(
  BuildContext context,
  double preferredWidth, {
  double horizontalMargin = 48,
}) {
  final screenWidth = MediaQuery.sizeOf(context).width;
  final availableWidth = screenWidth - horizontalMargin;
  if (availableWidth <= 0) {
    return preferredWidth;
  }
  return math.min(preferredWidth, availableWidth);
}

double _responsiveDialogHeight(
  BuildContext context,
  double preferredHeight, {
  double verticalMargin = 48,
}) {
  final screenHeight = MediaQuery.sizeOf(context).height;
  final availableHeight = screenHeight - verticalMargin;
  if (availableHeight <= 0) {
    return preferredHeight;
  }
  return math.min(preferredHeight, availableHeight);
}
