// ignore_for_file: implicit_dynamic_variable
// ignore_for_file: missing_whitespace_between_adjacent_strings
// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables
// ignore_for_file: prefer_function_declarations_over_variables
// ignore_for_file: avoid_types_on_closure_parameters
// ignore_for_file: unused_import

import 'package:flutter_spanned_controller/src/attribute_span.dart';
import 'package:flutter_spanned_controller/src/spanned_string.dart';
import 'package:flutter_spanned_controller/src/spanned_text_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'util.dart';

void main() {
  group('copyWith', () {
    final s = SpannedString('Test1', SpanList([sp(a, 0, 1)]));
    test('none', () {
      expect(s.copyWith(), s);
    });
    test('text', () {
      expect(SpannedString('Changed', SpanList([sp(a, 0, 1)])),
          s.copyWith(text: 'Changed'.characters));
    });
    test('spans', () {
      expect(SpannedString('Test1', SpanList([sp(b, 0, 1)])),
          s.copyWith(spans: SpanList([sp(b, 0, 1)])));
    });
  });

  group('collapse', () {
    const str = 'This is a test';
    final s = SpannedString(str, SpanList([sp(a, 0, 4), sp(b, 3, 7)]));
    test('collapsed range', () {
      expect(s.collapse(start: 1, end: 1), s);
      expect(s.collapse(start: 5, end: 5), s);
      expect(s.collapse(end: 0), s);
      expect(s.collapse(start: str.length), s);
    });
    test('text only', () {
      expect(
        s.collapse(start: 7, end: str.length),
        SpannedString('This is', SpanList([sp(a, 0, 4), sp(b, 3, 7)])),
      );
    });
    test('span', () {
      expect(
        s.collapse(start: 3, end: 5),
        SpannedString('Thiis a test', SpanList([sp(a, 0, 3), sp(b, 3, 5)])),
      );
    });
    test('everything', () {
      expect(
        s.collapse(start: 0, end: str.characters.length),
        SpannedString.empty(),
      );
    });
    test('start oob', () {
      expect(() => s.collapse(start: -1), throwsRangeError);
    });
    test('end oob', () {
      expect(() => s.collapse(end: str.length + 1), throwsRangeError);
    });
    test('end < start', () {
      expect(() => s.collapse(start: 3, end: 2), throwsArgumentError);
    });
  });

  group('insert', () {
    const str = 'This is a test';
    final s = SpannedString(str, SpanList([sp(a, 0, 4), sp(b, 3, 7)]));
    test('empty', () {
      expect(s.insert(1, ''.characters), s);
      expect(s.insert(5, ''.characters), s);
    });
    test('into empty', () {
      expect(
        SpannedString.empty().insert(0, 'Hello'.characters),
        SpannedString('Hello'),
      );
    });
    test('concat', () {
      final concat =
          s.concat(SpannedString(', or is it?', SpanList([sp(a, 0, 5)])));
      expect(
        concat,
        SpannedString(
          'This is a test, or is it?',
          SpanList(
            [
              sp(a, 0, 4),
              sp(b, 3, 7),
              sp(a, str.length, str.length + 5),
            ],
          ),
        ),
      );
    });
    test('concat merge', () {
      final s1 = SpannedString('bird', SpanList([sp(a, 1, 4)]));
      final s2 = SpannedString('word', SpanList([sp(a, 0, 2)]));
      expect(s1.concat(s2), SpannedString('birdword', SpanList([sp(a, 1, 6)])));
    });
    test('concat does not expand', () {
      final s1 = SpannedString('bird',
          SpanList([sp(a, 1, 4, ExpandRule.exclusive, ExpandRule.inclusive)]));
      final s2 = SpannedString('word', SpanList([sp(b, 0, 2)]));
      expect(
        s1.concat(s2),
        SpannedString(
            'birdword',
            SpanList([
              sp(a, 1, 4, ExpandRule.exclusive, ExpandRule.inclusive),
              sp(b, 4, 6)
            ])),
      );
    });
    test('index oob', () {
      expect(() => s.insert(-1, 'aaa'.characters), throwsRangeError);
    });
  });

  group('builder', () {
    test('text only', () {
      expect(
        (SpannedStringBuilder()
              ..write('Testing')
              ..writeln())
            .build(),
        SpannedString('Testing\n'),
      );
    });
    test('single span', () {
      expect(
        (SpannedStringBuilder()
              ..start(spt(a))
              ..write('Test')
              ..end(spt(a)))
            .build(),
        SpannedString('Test', SpanList([sp(a, 0, 4)])),
      );
    });
    test('unfinished span', () {
      expect(
        (SpannedStringBuilder()
              ..start(spt(a))
              ..write('Test'))
            .build(),
        SpannedString('Test', SpanList([sp(a, 0, 4)])),
      );
    });
    test('multiple spans', () {
      expect(
          (SpannedStringBuilder()
                ..start(spt(a))
                ..write('T')
                ..start(spt(b))
                ..write('es')
                ..end(spt(a))
                ..write('t')
                ..end(spt(b)))
              .build(),
          SpannedString('Test', SpanList([sp(a, 0, 3), sp(b, 1, 4)])));
    });
    test('segment style', () {
      expect(
          (SpannedStringBuilder()..write('Hi', [spt(a)])..write(':)', [spt(b)]))
              .build(),
          SpannedString('Hi:)', SpanList([sp(a, 0, 2), sp(b, 2, 4)])));
    });
    test('segment style merge', () {
      expect(
          (SpannedStringBuilder()..write('Hi', [spt(a)])..write(':)', [spt(a)]))
              .build(),
          SpannedString('Hi:)', SpanList([sp(a, 0, 4)])));
    });
  });
}
