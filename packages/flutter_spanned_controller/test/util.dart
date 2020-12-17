import 'package:equatable/equatable.dart';
import 'package:flutter_spanned_controller/flutter_spanned_controller.dart';

abstract class MockSpan extends TextAttribute with EquatableMixin {
  @override
  TextAttributeValue resolve(AttributeThemeData theme) {
    throw UnimplementedError();
  }

  @override
  List<Object?> get props => [];
}

AttributeSpanTemplate spt<T extends MockSpan>(
  T attr, [
  ExpandRule startAnchor = ExpandRule.exclusive,
  ExpandRule endAnchor = ExpandRule.exclusive,
]) =>
    AttributeSpanTemplate(attr, startAnchor, endAnchor);

AttributeSpan sp<T extends MockSpan>(
  T attr,
  int start,
  int end, [
  ExpandRule startAnchor = ExpandRule.exclusive,
  ExpandRule endAnchor = ExpandRule.exclusive,
]) =>
    AttributeSpan(
      attr,
      start,
      end,
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
