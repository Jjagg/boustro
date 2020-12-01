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
        (SpanController()
              ..shift(0, 3)
              ..add(sp(
                  a, 1, 2, InsertBehavior.exclusive, InsertBehavior.inclusive))
              ..collapse(TextRange(start: 1, end: 3)))
            .spans,
        [sp(a, 1, 1, InsertBehavior.exclusive, InsertBehavior.inclusive)],
      );
    });

    test('''remove useless span at the start''', () {
      expect(
        (SpanController()
              ..shift(0, 3)
              ..add(sp(
                  a, 1, 2, InsertBehavior.inclusive, InsertBehavior.exclusive))
              ..collapse(TextRange(start: 0, end: 2)))
            .spans,
        [],
      );
    });

    test('''remove useless span collapsed''', () {
      expect(
        (SpanController()
              ..shift(0, 3)
              ..add(sp(
                  a, 1, 2, InsertBehavior.exclusive, InsertBehavior.exclusive))
              ..collapse(TextRange(start: 1, end: 2)))
            .spans,
        [],
      );
    });

    test('''do not remove unexpandable span not collapsed''', () {
      expect(
        (SpanController()
              ..shift(0, 3)
              ..add(sp(
                  a, 1, 3, InsertBehavior.exclusive, InsertBehavior.exclusive))
              ..collapse(TextRange(start: 1, end: 2)))
            .spans,
        [sp(a, 1, 2, InsertBehavior.exclusive, InsertBehavior.exclusive)],
      );
    });
  });

  group('shift', () {
    test('empty before-after', () {
      expect(
          (SpanController()
                ..add(sp(a, 0, 0, InsertBehavior.exclusive,
                    InsertBehavior.inclusive))
                ..shift(0, 2))
              .spans,
          [sp(a, 0, 2, InsertBehavior.exclusive, InsertBehavior.inclusive)]);
    });

    test('insertion before', () {
      expect(
        (SpanController()
              ..shift(0, 5)
              ..add(sp(a, 3, 4))
              ..shift(1, 3))
            .spans,
        [sp(a, 6, 7)],
      );
    });
  });

  group('add', () {
    test('merge touching', () {
      final l = SpanController()..shift(0, 5);
      final s1 = sp(a, 1, 2);
      final s2 = sp(a, 2, 3);
      expect((l..add(s1)..add(s2)).spans, [sp(a, 1, 3)]);
    });
    test('merge bridge', () {
      final l = SpanController()..shift(0, 10);
      final s1 = sp(a, 1, 3);
      final s2 = sp(a, 5, 8);
      final s3 = sp(a, 3, 5);
      expect((l..add(s1)..add(s2)..add(s3)).spans, [sp(a, 1, 8)]);
    });
    test('merge containing', () {
      final l = SpanController()..shift(0, 10);
      final s1 = sp(a, 1, 3);
      final s2 = sp(a, 5, 8);
      final s3 = sp(a, 0, 9);
      expect((l..add(s1)..add(s2)..add(s3)).spans, [sp(a, 0, 9)]);
    });
  });

  group('segments', () {
    test('empty', () {
      expect(SpanController().segments, isEmpty);
    });

    test('plain', () {
      expect((SpanController()..shift(0, 3)).segments,
          [AttributeSegment([], TextRange(start: 0, end: 3))]);
    });

    test('complex', () {
      final sa = sp(a, 1, 7);
      final sb = sp(b, 1, 8);
      final sc = sp(c, 2, 5);
      final sd = sp(d, 2, 5);
      final se = sp(e, 2, 6);
      final sf = sp(f, 2, 10);

      expect(
          (SpanController()
                ..shift(0, 10)
                ..add(sa)
                ..add(sb)
                ..add(sc)
                ..add(sd)
                ..add(se)
                ..add(sf)
                ..shift(10, 3))
              .segments,
          <AttributeSegment>[
            AttributeSegment([], TextRange(start: 0, end: 1)),
            AttributeSegment(
                [sa.attribute, sb.attribute], TextRange(start: 1, end: 2)),
            AttributeSegment([a, b, c, d, e, f], TextRange(start: 2, end: 5)),
            AttributeSegment([a, b, e, f], TextRange(start: 5, end: 6)),
            AttributeSegment([a, b, f], TextRange(start: 6, end: 7)),
            AttributeSegment([b, f], TextRange(start: 7, end: 8)),
            AttributeSegment([f], TextRange(start: 8, end: 10)),
            AttributeSegment([], TextRange(start: 10, end: 13)),
          ]);
    });
  });

  group('diff', () {
    const diffStrings = SpannedTextController.diffStrings;
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

abstract class MockSpan extends TextAttribute {
  @override
  TextStyle apply(TextStyle style) => style;
}

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
