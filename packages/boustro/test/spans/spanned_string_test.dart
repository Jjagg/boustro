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

import 'util.dart';

void main() {
  group('copyWith', () {
    final s = AttributedText('Test1', AttributeSpanList([sp(a, 0, 1)]));
    test('none', () {
      expect(s.copyWith(), s);
    });
    test('text', () {
      expect(AttributedText('Changed', AttributeSpanList([sp(a, 0, 1)])),
          s.copyWith(text: 'Changed'.characters));
    });
    test('spans', () {
      expect(AttributedText('Test1', AttributeSpanList([sp(b, 0, 1)])),
          s.copyWith(spans: AttributeSpanList([sp(b, 0, 1)])));
    });
  });

  group('collapse', () {
    const str = 'This is a test';
    final s = AttributedText(str, AttributeSpanList([sp(a, 0, 4), sp(b, 3, 7)]));
    test('collapsed range', () {
      expect(s.collapse(start: 1, end: 1), s);
      expect(s.collapse(start: 5, end: 5), s);
      expect(s.collapse(end: 0), s);
      expect(s.collapse(start: str.length), s);
    });
    test('text only', () {
      expect(
        s.collapse(start: 7, end: str.length),
        AttributedText('This is', AttributeSpanList([sp(a, 0, 4), sp(b, 3, 7)])),
      );
    });
    test('span', () {
      expect(
        s.collapse(start: 3, end: 5),
        AttributedText(
            'Thiis a test', AttributeSpanList([sp(a, 0, 3), sp(b, 3, 5)])),
      );
    });
    test('everything', () {
      expect(
        s.collapse(start: 0, end: str.characters.length),
        AttributedText.empty,
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
    test('start and end null', () {
      expect(s.collapse, throwsArgumentError);
    });
  });

  group('insert', () {
    const str = 'This is a test';
    final s = AttributedText(str, AttributeSpanList([sp(a, 0, 4), sp(b, 3, 7)]));
    test('empty', () {
      expect(s.insert(1, ''.characters), s);
      expect(s.insert(5, ''.characters), s);
    });
    test('into empty', () {
      expect(
        AttributedText.empty.insert(0, 'Hello'.characters),
        AttributedText('Hello'),
      );
    });
    test('concat', () {
      final concat = s.concat(
          AttributedText(', or is it?', AttributeSpanList([sp(a, 0, 5)])));
      expect(
        concat,
        AttributedText(
          'This is a test, or is it?',
          AttributeSpanList(
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
      final s1 = AttributedText('bird', AttributeSpanList([sp(a, 1, 4)]));
      final s2 = AttributedText('word', AttributeSpanList([sp(a, 0, 2)]));
      expect(s1.concat(s2),
          AttributedText('birdword', AttributeSpanList([sp(a, 1, 6)])));
    });
    test('concat does not expand', () {
      final s1 =
          AttributedText('bird', AttributeSpanList([sp(RuleAttr.exInc, 1, 4)]));
      final s2 = AttributedText('word', AttributeSpanList([sp(b, 0, 2)]));
      expect(
        s1.concat(s2),
        AttributedText('birdword',
            AttributeSpanList([sp(RuleAttr.exInc, 1, 4), sp(b, 4, 6)])),
      );
    });
    test('index oob', () {
      expect(() => s.insert(-1, 'aaa'.characters), throwsRangeError);
    });
  });

  group('applyDiff', () {
    const str = 'This is a test';
    final s = AttributedText(str, AttributeSpanList([sp(a, 0, 4), sp(b, 3, 7)]));
    test('insert', () {
      expect(
        s.applyDiff(StringDiff(0, ''.characters, 'OK'.characters)),
        AttributedText('OK$str', AttributeSpanList([sp(a, 2, 6), sp(b, 5, 9)])),
      );
    });
    test('delete', () {
      expect(
        s.applyDiff(StringDiff(2, 'is'.characters, ''.characters)),
        AttributedText(
            'Th is a test', AttributeSpanList([sp(a, 0, 2), sp(b, 2, 5)])),
      );
    });
    test('insert delete', () {
      expect(
        s.applyDiff(StringDiff(2, 'is'.characters, 'OK'.characters)),
        AttributedText(
            'ThOK is a test', AttributeSpanList([sp(a, 0, 2), sp(b, 4, 7)])),
      );
    });
  });

  group('buildTextSpan', () {
    testWidgets('plain', (t) async {
      Builder(
        builder: (context) {
          final sp = AttributedText('Hello')
              .buildTextSpan(context: context, style: TextStyle());
          expect(sp, TextSpan(text: 'Hello', style: TextStyle()));

          return Container();
        },
      );
    });
  });

  group('builder', () {
    test('text only', () {
      expect(
        (AttributedTextBuilder()
              ..write('Testing')
              ..writeln()
              ..writeln('😴'))
            .build(),
        AttributedText('Testing\n😴\n'),
      );
    });
    test('single span', () {
      expect(
        (AttributedTextBuilder()
              ..start(a)
              ..write('Test')
              ..end(a))
            .build(),
        AttributedText('Test', AttributeSpanList([sp(a, 0, 4)])),
      );
    });
    test('unfinished span', () {
      expect(
        (AttributedTextBuilder()
              ..start(a)
              ..write('Test'))
            .build(),
        AttributedText('Test', AttributeSpanList([sp(a, 0, 4)])),
      );
    });
    test('multiple spans', () {
      expect(
          (AttributedTextBuilder()
                ..start(a)
                ..write('T')
                ..start(b)
                ..write('es')
                ..end(a)
                ..write('t')
                ..end(b))
              .build(),
          AttributedText('Test', AttributeSpanList([sp(a, 0, 3), sp(b, 1, 4)])));
    });
    test('end unstarted span throws', () {
      expect(() => AttributedTextBuilder().end(a), throwsStateError);
    });
    test('line style', () {
      expect(
        (AttributedTextBuilder()
              ..lineStyle(a)
              ..write('Test'))
            .build(),
        AttributedText(
          'Test',
          AttributeSpanList([sp(a, 0, maxSpanLength)]),
        ),
      );
    });
    test('segment style', () {
      expect(
          (AttributedTextBuilder()
                ..write('Hi', [a])
                ..write(':)', [b]))
              .build(),
          AttributedText('Hi:)', AttributeSpanList([sp(a, 0, 2), sp(b, 2, 4)])));
    });
    test('segment style merge', () {
      expect(
          (AttributedTextBuilder()
                ..write('Hi', [a])
                ..write(':)', [a]))
              .build(),
          AttributedText('Hi:)', AttributeSpanList([sp(a, 0, 4)])));
    });
  });
}
