// ignore_for_file: implicit_dynamic_variable
// ignore_for_file: missing_whitespace_between_adjacent_strings
// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables
// ignore_for_file: prefer_function_declarations_over_variables
// ignore_for_file: avoid_types_on_closure_parameters

import 'package:flutter_spanned_controller/src/attribute_span.dart';
import 'package:flutter_spanned_controller/src/spanned_string.dart';
import 'package:flutter_spanned_controller/src/spanned_text_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SpannedString ctor', () {
    test('empty', () {
      final s = SpannedString('', SpanList());
      expect(s.length, 0);
      expect(s.text, isEmpty);
      expect(s.spans.spans, isEmpty);
    });
  });
}
