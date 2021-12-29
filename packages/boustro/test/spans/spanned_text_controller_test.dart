// ignore_for_file: implicit_dynamic_variable
// ignore_for_file: missing_whitespace_between_adjacent_strings
// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables
// ignore_for_file: prefer_function_declarations_over_variables
// ignore_for_file: avoid_types_on_closure_parameters
// ignore_for_file: unused_import
// ignore_for_file: directives_ordering

import 'package:boustro/src/spans/attribute_span.dart';
import 'package:boustro/src/spans/attributed_text.dart';
import 'package:boustro/src/spans/attributed_text_editing_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('diff', () {
    const diffStrings = AttributedTextEditingController.diffStrings;
    test('empty', () {
      expect(
          diffStrings('', '', 0), StringDiff(0, ''.characters, ''.characters));
    });
    test('identical', () {
      expect(diffStrings('Hello', 'Hello', 3),
          StringDiff(3, ''.characters, ''.characters));
    });
    test('single', () {
      expect(diffStrings('o', 'a', 1),
          StringDiff(0, 'o'.characters, 'a'.characters));
    });
    test('simple', () {
      expect(diffStrings('Hi', 'Higher', 6),
          StringDiff(2, ''.characters, 'gher'.characters));
    });
    test('empty insert', () {
      expect(diffStrings('', 'Yeah', 4),
          StringDiff(0, ''.characters, 'Yeah'.characters));
    });
    test('delete to empty', () {
      expect(diffStrings('Yeah', '', 0),
          StringDiff(0, 'Yeah'.characters, ''.characters));
    });
    test('duplicate characters', () {
      expect(diffStrings('booh', 'boooh', 2),
          StringDiff(1, ''.characters, 'o'.characters));
      expect(diffStrings('booh', 'boooh', 3),
          StringDiff(2, ''.characters, 'o'.characters));
      expect(diffStrings('booh', 'boooh', 4),
          StringDiff(3, ''.characters, 'o'.characters));
    });

    test('Replace all', () {
      final diff = AttributedTextEditingController.diffStrings(
        'Hey',
        'Okay',
        4,
      );
      expect(diff, StringDiff(0, 'Hey'.characters, 'Okay'.characters));
    });

    test('Repeated', () {
      final diff = AttributedTextEditingController.diffStrings('aaaaaa', 'aaa', 1);
      expect(diff, StringDiff(1, 'aaa'.characters, ''.characters));
    });

    test('delete insert', () {
      final diff = AttributedTextEditingController.diffStrings('Heyo', 'Helo', 3);
      expect(diff, StringDiff(2, 'y'.characters, 'l'.characters));
    });

    test('Emoji', () {
      final diff = AttributedTextEditingController.diffStrings(
          '🍕🍔', '🍕🍟', '🍕🍟'.length);
      expect(diff, StringDiff(1, '🍔'.characters, '🍟'.characters));
    });

    test('Emoji overlap', () {
      final diff =
          AttributedTextEditingController.diffStrings('😀', '😃', '😃'.length);
      expect(diff, StringDiff(0, '😀'.characters, '😃'.characters));
    });
  });
}
