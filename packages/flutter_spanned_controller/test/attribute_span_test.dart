// ignore_for_file: implicit_dynamic_variable
// ignore_for_file: missing_whitespace_between_adjacent_strings
// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables
// ignore_for_file: prefer_function_declarations_over_variables
// ignore_for_file: avoid_types_on_closure_parameters
// ignore_for_file: directives_ordering

import 'package:flutter_spanned_controller/src/attribute_span.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'util.dart';

void main() {
  group('splice TextRange', () {
    test('', () {
      final t = Range(3, 5);

      expect(
        t.splice(Range(0, 2)),
        Range(1, 3),
      );

      expect(
        t.splice(Range(0, 3)),
        Range(0, 2),
      );

      expect(
        t.splice(Range(1, 4)),
        Range(1, 2),
      );

      expect(
        t.splice(Range(4, 5)),
        Range(3, 4),
      );

      expect(
        t.splice(Range(4, 10)),
        Range(3, 4),
      );

      expect(
        t.splice(Range(3, 5)),
        Range(3, 3),
      );

      expect(
        t.splice(Range(2, 5)),
        Range(2, 2),
      );

      expect(
        t.splice(Range(3, 6)),
        Range(3, 3),
      );

      expect(
        t.splice(Range(2, 6)),
        null,
      );
    });
  });

  group('collapse', () {
    test('''remove collapsed span at the end''', () {
      expect(
        SpanList([sp(RuleAttr.exInc, 1, 2)]).collapse(Range(1, 3)).iter,
        <dynamic>[],
      );
    });

    test('''remove useless span at the start''', () {
      expect(
        SpanList([sp(RuleAttr.incEx, 1, 2)]).collapse(Range(0, 2)).iter,
        <dynamic>[],
      );
    });

    test('''remove useless span collapsed''', () {
      expect(
        SpanList([sp(RuleAttr.exEx, 1, 2)]).collapse(Range(1, 2)).iter,
        <dynamic>[],
      );
    });

    test('''do not remove unexpandable span not collapsed''', () {
      expect(
        SpanList([sp(RuleAttr.exEx, 1, 3)]).collapse(Range(1, 2)).iter,
        [sp(RuleAttr.exEx, 1, 2)],
      );
    });
  });

  group('shift', () {
    test('insertion before', () {
      expect(
        SpanList.empty.shift(0, 5).merge(sp(a, 3, 4)).shift(1, 3).iter,
        [sp(a, 6, 7)],
      );
    });
  });

  group('merge', () {
    test('merge touching', () {
      final l = SpanList.empty.shift(0, 5);
      final s1 = sp(a, 1, 2);
      final s2 = sp(a, 2, 3);
      expect(l.merge(s1).merge(s2).iter, [sp(a, 1, 3)]);
    });
    test('merge bridge', () {
      const l = SpanList.empty;
      final s1 = sp(a, 1, 3);
      final s2 = sp(a, 5, 8);
      final s3 = sp(a, 3, 5);
      expect(l.merge(s1).merge(s2).merge(s3).iter, [sp(a, 1, 8)]);
      expect(SpanList([s1, s2, s3]).iter, [sp(a, 1, 8)]);
    });
    test('constructor merges all', () {
      final s1 = sp(a, 1, 3);
      final s2 = sp(a, 5, 8);
      final s3 = sp(a, 3, 5);
      expect(SpanList([s1, s2, s3]).iter, [sp(a, 1, 8)]);
    });

    test('merge containing', () {
      final l = SpanList.empty.shift(0, 10);
      final s1 = sp(a, 1, 3);
      final s2 = sp(a, 5, 8);
      final s3 = sp(a, 0, 9);
      expect(l.merge(s1).merge(s2).merge(s3).iter, [sp(a, 0, 9)]);
    });
  });

  group('segments', () {
    test('empty', () {
      expect(SpanList.empty.getSegments(''.characters), isEmpty);
    });

    test('plain', () {
      expect(SpanList.empty.getSegments('hey'.characters),
          [AttributeSegment.from('hey'.characters, [])]);
    });

    test('spans can go past end', () {
      expect(SpanList([sp(a, 0, 10)]).getSegments('hey'.characters), [
        AttributeSegment.from('hey'.characters, [a])
      ]);
    });

    test('complex', () {
      expect(
          (SpanList([
            sp(a, 1, 7),
            sp(b, 1, 8),
            sp(c, 2, 5),
            sp(d, 2, 5),
            sp(e, 2, 6),
            sp(f, 2, 10),
          ]).shift(10, 3))
              .getSegments('Hello, World!'.characters),
          <AttributeSegment>[
            AttributeSegment.from('H'.characters, []),
            AttributeSegment.from('e'.characters, [a, b]),
            AttributeSegment.from('llo'.characters, [a, b, c, d, e, f]),
            AttributeSegment.from(','.characters, [a, b, e, f]),
            AttributeSegment.from(' '.characters, [a, b, f]),
            AttributeSegment.from('W'.characters, [b, f]),
            AttributeSegment.from('or'.characters, [f]),
            AttributeSegment.from('ld!'.characters, []),
          ]);
    });

    test('emoji', () {
      expect(
          SpanList([sp(a, 1, 3)]).getSegments('👨‍👩‍👧‍👦a🥙'.characters),
          <AttributeSegment>[
            AttributeSegment.from('👨‍👩‍👧‍👦'.characters, []),
            AttributeSegment.from('a🥙'.characters, [a]),
          ]);
    });
  });

  test('expand rule toBracketString', () {
    expect(ExpandRule.inclusive.toBracketStr(true), ']');
    expect(ExpandRule.inclusive.toBracketStr(false), '[');
    expect(ExpandRule.exclusive.toBracketStr(true), '|');
    expect(ExpandRule.exclusive.toBracketStr(false), '|');
    expect(ExpandRule.fixed.toBracketStr(true), '_');
    expect(ExpandRule.fixed.toBracketStr(false), '_');
  });
}
