import 'package:flutter/material.dart';

import '../../app/theme/app_palette.dart';
import '../../features/movements/domain/movements.dart';

extension MovementTypeView on MovementType {
  Color get color => switch (this) {
    MovementType.entry => AppPalette.success,
    MovementType.exit => AppPalette.danger,
    MovementType.adjustment => AppPalette.navy,
  };

  IconData get icon => switch (this) {
    MovementType.entry => Icons.south_west_rounded,
    MovementType.exit => Icons.north_east_rounded,
    MovementType.adjustment => Icons.tune_rounded,
  };
}
