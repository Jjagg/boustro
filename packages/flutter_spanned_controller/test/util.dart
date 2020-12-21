import 'package:equatable/equatable.dart';
import 'package:flutter_spanned_controller/flutter_spanned_controller.dart';

abstract class MockAttr extends TextAttribute with EquatableMixin {
  const MockAttr();

  @override
  SpanExpandRules get expandRules => SpanExpandRules(
        ExpandRule.exclusive,
        ExpandRule.exclusive,
      );

  @override
  TextAttributeValue resolve(AttributeThemeData theme) {
    throw UnimplementedError();
  }

  @override
  List<Object?> get props => [];
}

AttributeSpan sp<T extends MockAttr>(T attr, int start, int end) {
  return AttributeSpan(
    attr,
    start,
    end,
  );
}

final a = MockAttrA();
final b = MockAttrB();
final c = MockAttrC();
final d = MockAttrD();
final e = MockAttrE();
final f = MockAttrF();

class MockAttrA extends MockAttr {}

class MockAttrB extends MockAttr {}

class MockAttrC extends MockAttr {}

class MockAttrD extends MockAttr {}

class MockAttrE extends MockAttr {}

class MockAttrF extends MockAttr {}

class RuleAttr extends MockAttr {
  const RuleAttr(this.expandRules);

  @override
  final SpanExpandRules expandRules;

  static final RuleAttr exEx =
      RuleAttr(SpanExpandRules(ExpandRule.exclusive, ExpandRule.exclusive));
  static final RuleAttr exInc =
      RuleAttr(SpanExpandRules(ExpandRule.exclusive, ExpandRule.inclusive));
  static final RuleAttr incEx =
      RuleAttr(SpanExpandRules(ExpandRule.inclusive, ExpandRule.exclusive));
  static final RuleAttr incInc =
      RuleAttr(SpanExpandRules(ExpandRule.inclusive, ExpandRule.inclusive));
  static final RuleAttr fixed = RuleAttr(SpanExpandRules.fixed());
}
