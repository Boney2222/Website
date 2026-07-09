import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pan_late_pyar/main.dart';

void main() {
  testWidgets('PanLatePyarApp builds', (WidgetTester tester) async {
    await tester.pumpWidget(const PanLatePyarApp());
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });

  test('card number formatter groups digits after every 4 numbers', () {
    final formatter = CardNumberInputFormatter();
    final value = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(text: '4242424242424242'),
    );

    expect(value.text, '4242 4242 4242 4242');
  });

  test('card number validator uses overall Luhn validation', () {
    expect(cardNumberValidator('4242 4242 4242 4242'), isNull);
    expect(cardNumberValidator('4242 4242 4242 4241'), isNotNull);
    expect(cardNumberValidator('1234'), isNotNull);
  });

  test('card expiry formatter inserts slash after the month', () {
    final formatter = CardExpiryInputFormatter();
    final value = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(text: '1230'),
    );

    expect(value.text, '12/30');
  });

  test('card expiry validator rejects expired and malformed dates', () {
    expect(cardExpiryValidator('12/30'), isNull);
    expect(cardExpiryValidator('12/20'), isNotNull);
    expect(cardExpiryValidator('13/30'), isNotNull);
  });

  test('card CVC validator requires 3 or 4 digits', () {
    expect(cardCvvValidator('123'), isNull);
    expect(cardCvvValidator('1234'), isNull);
    expect(cardCvvValidator('12'), isNotNull);
    expect(cardCvvValidator('12a'), isNotNull);
  });
}
