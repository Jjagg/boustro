// ignore_for_file: implicit_dynamic_variable
// ignore_for_file: missing_whitespace_between_adjacent_strings
// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables
// ignore_for_file: prefer_function_declarations_over_variables
// ignore_for_file: avoid_types_on_closure_parameters

import 'package:flutter_spanned_controller/src/attribute_span.dart';
import 'package:flutter_spanned_controller/src/spanned_text_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('splice TextRange', () {
    test('', () {
      final t = TextRange(start: 3, end: 5);

      expect(
        t.splice(TextRange(start: 0, end: 2)),
        TextRange(start: 1, end: 3),
      );

      expect(
        t.splice(TextRange(start: 0, end: 3)),
        TextRange(start: 0, end: 2),
      );

      expect(
        t.splice(TextRange(start: 1, end: 4)),
        TextRange(start: 1, end: 2),
      );

      expect(
        t.splice(TextRange(start: 4, end: 5)),
        TextRange(start: 3, end: 4),
      );

      expect(
        t.splice(TextRange(start: 4, end: 10)),
        TextRange(start: 3, end: 4),
      );

      expect(
        t.splice(TextRange(start: 3, end: 5)),
        TextRange(start: 3, end: 3),
      );

      expect(
        t.splice(TextRange(start: 2, end: 5)),
        TextRange(start: 2, end: 2),
      );

      expect(
        t.splice(TextRange(start: 3, end: 6)),
        TextRange(start: 3, end: 3),
      );

      expect(
        t.splice(TextRange(start: 2, end: 6)),
        null,
      );
    });
  });

  group('collapse', () {
    test('''do not remove expandable span at the end''', () {
      expect(
        SpanList([
          sp(a, 1, 2, InsertBehavior.exclusive, InsertBehavior.inclusive)
        ]).collapse(TextRange(start: 1, end: 3)).spans,
        [sp(a, 1, 1, InsertBehavior.exclusive, InsertBehavior.inclusive)],
      );
    });

    test('''remove useless span at the start''', () {
      expect(
        SpanList([
          sp(a, 1, 2, InsertBehavior.inclusive, InsertBehavior.exclusive)
        ]).collapse(TextRange(start: 0, end: 2)).spans,
        <dynamic>[],
      );
    });

    test('''remove useless span collapsed''', () {
      expect(
        SpanList([
          sp(a, 1, 2, InsertBehavior.exclusive, InsertBehavior.exclusive)
        ]).collapse(TextRange(start: 1, end: 2)).spans,
        <dynamic>[],
      );
    });

    test('''do not remove unexpandable span not collapsed''', () {
      expect(
        SpanList([
          sp(a, 1, 3, InsertBehavior.exclusive, InsertBehavior.exclusive)
        ]).collapse(TextRange(start: 1, end: 2)).spans,
        [sp(a, 1, 2, InsertBehavior.exclusive, InsertBehavior.exclusive)],
      );
    });
  });

  group('shift', () {
    test('empty before-after', () {
      expect(
          SpanList()
              .merge(sp(
                  a, 0, 0, InsertBehavior.exclusive, InsertBehavior.inclusive))
              .shift(0, 2)
              .spans,
          [sp(a, 0, 2, InsertBehavior.exclusive, InsertBehavior.inclusive)]);
    });

    test('insertion before', () {
      expect(
        SpanList().shift(0, 5).merge(sp(a, 3, 4)).shift(1, 3).spans,
        [sp(a, 6, 7)],
      );
    });
  });

  group('merge', () {
    test('merge touching', () {
      final l = SpanList().shift(0, 5);
      final s1 = sp(a, 1, 2);
      final s2 = sp(a, 2, 3);
      expect(l.merge(s1).merge(s2).spans, [sp(a, 1, 3)]);
    });
    test('merge bridge', () {
      final l = SpanList().shift(0, 10);
      final s1 = sp(a, 1, 3);
      final s2 = sp(a, 5, 8);
      final s3 = sp(a, 3, 5);
      expect(l.merge(s1).merge(s2).merge(s3).spans, [sp(a, 1, 8)]);
    });
    test('merge containing', () {
      final l = SpanList().shift(0, 10);
      final s1 = sp(a, 1, 3);
      final s2 = sp(a, 5, 8);
      final s3 = sp(a, 0, 9);
      expect(l.merge(s1).merge(s2).merge(s3).spans, [sp(a, 0, 9)]);
    });
  });

  group('segments', () {
    test('empty', () {
      expect(SpanList().getSegments(0), isEmpty);
    });

    test('plain', () {
      expect(SpanList().getSegments(3),
          [AttributeSegment.from([], TextRange(start: 0, end: 3))]);
    });

    test('complex', () {
      final sa = sp(a, 1, 7);
      final sb = sp(b, 1, 8);
      final sc = sp(c, 2, 5);
      final sd = sp(d, 2, 5);
      final se = sp(e, 2, 6);
      final sf = sp(f, 2, 10);

      expect(
          (SpanList()
                  .shift(0, 10)
                  .merge(sa)
                  .merge(sb)
                  .merge(sc)
                  .merge(sd)
                  .merge(se)
                  .merge(sf)
                  .shift(10, 3))
              .getSegments(13),
          <AttributeSegment>[
            AttributeSegment.from([], TextRange(start: 0, end: 1)),
            AttributeSegment.from(
                [sa.attribute, sb.attribute], TextRange(start: 1, end: 2)),
            AttributeSegment.from(
                [a, b, c, d, e, f], TextRange(start: 2, end: 5)),
            AttributeSegment.from([a, b, e, f], TextRange(start: 5, end: 6)),
            AttributeSegment.from([a, b, f], TextRange(start: 6, end: 7)),
            AttributeSegment.from([b, f], TextRange(start: 7, end: 8)),
            AttributeSegment.from([f], TextRange(start: 8, end: 10)),
            AttributeSegment.from([], TextRange(start: 10, end: 13)),
          ]);
    });
  });

  group('diff', () {
    const diffStrings = SpannedTextEditingController.diffStrings;
    test('empty', () {
      expect(diffStrings('', '', 0), StringDiff(0, '', ''));
    });
    test('identical', () {
      expect(diffStrings('Hello', 'Hello', 3), StringDiff(3, '', ''));
    });
    test('simple', () {
      expect(diffStrings('Hi', 'Higher', 6), StringDiff(2, '', 'gher'));
    });
    test('empty insert', () {
      expect(diffStrings('', 'Yeah', 4), StringDiff(0, '', 'Yeah'));
    });
    test('delete to empty', () {
      expect(diffStrings('Yeah', '', 0), StringDiff(0, 'Yeah', ''));
    });
    test('duplicate characters', () {
      expect(diffStrings('booh', 'boooh', 2), StringDiff(1, '', 'o'));
      expect(diffStrings('booh', 'boooh', 3), StringDiff(2, '', 'o'));
      expect(diffStrings('booh', 'boooh', 4), StringDiff(3, '', 'o'));
    });
    test('unsolvable', () {
      expect(() => diffStrings('booh', 'boooh', 1), throwsAssertionError);
    });
  });
}

abstract class MockSpan extends TextAttribute {}

AttributeSpan sp<T extends MockSpan>(
  T attr,
  int start,
  int end, [
  InsertBehavior startAnchor = InsertBehavior.exclusive,
  InsertBehavior endAnchor = InsertBehavior.exclusive,
]) =>
    AttributeSpan(
      attr,
      TextRange(start: start, end: end),
      startAnchor,
      endAnchor,
    );

final a = MockSpanA();
final b = MockSpanB();
final c = MockSpanC();
final d = MockSpanD();
final e = MockSpanE();
final f = MockSpanF();

class MockSpanA extends MockSpan {}

class MockSpanB extends MockSpan {}

class MockSpanC extends MockSpan {}

class MockSpanD extends MockSpan {}

class MockSpanE extends MockSpan {}

class MockSpanF extends MockSpan {}
