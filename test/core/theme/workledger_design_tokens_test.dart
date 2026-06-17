import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workledger/core/theme/workledger_design_tokens.dart';

void main() {
  test('creates Airtable-inspired WorkLedger theme tokens', () {
    final ThemeData theme = createWorkLedgerTheme();

    expect(theme.colorScheme.primary, workLedgerColorPrimary);
    expect(theme.scaffoldBackgroundColor, workLedgerColorCanvas);
    expect(theme.appBarTheme.foregroundColor, workLedgerColorInk);
    expect(workLedgerButtonTextStyle.fontWeight, FontWeight.w500);
    expect(workLedgerPricingCardTitleTextStyle.fontWeight, FontWeight.w500);
    expect(workLedgerPricingCardTitleTextStyle.fontFamily, isNull);
    expect(theme.dividerTheme.color, workLedgerColorHairline);
    expect(theme.listTileTheme.iconColor, workLedgerColorInk);
  });
}
