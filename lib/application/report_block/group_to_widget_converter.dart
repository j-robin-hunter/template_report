/*
 * Copyright (c) 2024 Robin Hunter rhunter@crml.com
 *  All rights reserved
 *
 * This work must not be copied, used or derived from either
 * or via any medium without the express written permission
 * and license from the owner
 */
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:sprintf/sprintf.dart';
import 'delta_insert_op.dart';
import 'grouper/group_types.dart';

class OpConverterOptions {
  double indentPixels;

  OpConverterOptions({
    this.indentPixels = 20,
  });
}

class GroupToWidgetConverter {
  late final OpConverterOptions options;
  final TDataGroup group;

  GroupToWidgetConverter(this.group, [OpConverterOptions? options]) {
    this.options = options ?? OpConverterOptions();
  }

  static List<String> bullets = ['\u2022 ', '\u25E6 ', '\u2043 '];
  List<int?> numberMarker = [];

  Widget getWidget() {
    switch (group.runtimeType) {
      case const (ListGroup):
        numberMarker = [];
        return listGroup((group as ListGroup).items);
      case const (BlockGroup):
        return blockGroup(group as BlockGroup);
      default:
        return inlineGroup((group as InlineGroup).ops);
    }
  }

  Widget listGroup(List<ListItem> items) {
    List<Widget> children = [];
    for (ListItem item in items) {
      if (item.item.runtimeType == BlockGroup) {
        children.add(blockGroup(item.item));
      }
      if (item.innerList != null) {
        children.add(listGroup(item.innerList!.items));
      }
    }
    return ListView(shrinkWrap: true, children: children);
  }

  Widget blockGroup(BlockGroup group) {
    int indents = group.op.attributes['indent'] ?? 0;
    final opsLen = group.ops.length - 1;
    String value = group.op.insert.value;
    if (group.op.attributes['list'] == 'bullet') {
      value = sprintf('% 3s  ', [bullets[indents % bullets.length]]);
      indents += 1;
    }
    if (group.op.attributes['list'] == 'ordered') {
      numberMarker.length = indents + 1;
      numberMarker[indents] = numberMarker[indents] == null ? 1 : numberMarker[indents]! + 1;
      value = sprintf('% 3s. ', [indents % 2 == 0 ? numberMarker[indents].toString() : numberMarker[indents]!.toRomanNumeral()]);
      indents += 1;
    }
    return Padding(
      padding: EdgeInsets.only(left: indents * options.indentPixels),
      child: Text.rich(
        TextSpan(
          text: value == '\n' ? '' : value,
          style: textStyleFromAttributes(group.op.attributes.attrs),
          children: group.ops.mapIndexed((i, op) {
            if (i > 0 && i == opsLen && op.isJustNewline()) {
              return const WidgetSpan(
                child: Text(''),
              );
            }
            return styledText(op.insert.value, op.attributes.attrs);
          }).toList(),
        ),
      ),
    );
  }

  Widget inlineGroup(List<DeltaInsertOp> ops) {
    final opsLen = ops.length - 1;
    return Text.rich(
      TextSpan(
        children: ops.mapIndexed((i, op) {
          if (i > 0 && i == opsLen && op.isJustNewline()) {
            return const WidgetSpan(
              child: Text(''),
            );
          }
          return styledText(op.insert.value, op.attributes.attrs);
        }).toList(),
      ),
    );
  }

  InlineSpan styledText(String text, Map<String, dynamic> attributes) {
    if (text == '\n') {
      return const TextSpan(text: '\n');
    }
    double offset = 0;
    if (attributes.containsKey('script')) {
      if (attributes['script'] == 'super') {
        offset = -5;
      } else {
        offset = 5;
      }
    }
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Transform.translate(
        offset: Offset(0.0, offset),
        child: Text(text, style: textStyleFromAttributes(attributes)),
      ),
    );
  }

  TextStyle textStyleFromAttributes(Map<String, dynamic> attributes) {
    TextStyle textStyle = const TextStyle();
    for (final attribute in attributes.keys) {
      switch (attribute) {
        case 'color':
          Color color = textStyle.color ?? Colors.black54;
          if (int.tryParse(attributes[attribute].substring(1), radix: 16) != null) {
            color = Color(int.parse(attributes[attribute].substring(1), radix: 16));
          }
          textStyle = textStyle.copyWith(color: color, decorationColor: color);
          break;
        case 'background':
          Color color = textStyle.color ?? Colors.black54;
          if (int.tryParse(attributes[attribute].substring(1), radix: 16) != null) {
            color = Color(int.parse(attributes[attribute].substring(1), radix: 16));
          }
          textStyle = textStyle.copyWith(backgroundColor: color);
          break;
        case 'bold':
          textStyle = textStyle.copyWith(fontWeight: FontWeight.bold);
          break;
        case 'italic':
          textStyle = textStyle.copyWith(fontStyle: FontStyle.italic);
          break;
        case 'underline':
          textStyle = textStyle.copyWith(decoration: TextDecoration.underline);
          break;
        case 'size':
          switch (attributes[attribute]) {
            case 'small':
              textStyle = textStyle.copyWith(fontSize: textStyle.fontSize! * 0.8);
              break;
            case 'large':
              textStyle = textStyle.copyWith(fontSize: textStyle.fontSize! * 1.4);
              break;
            case 'huge':
              textStyle = textStyle.copyWith(fontSize: textStyle.fontSize! * 1.8);
              break;
          }
          break;
        case 'script':
          if (attributes[attribute] == 'super') {
            textStyle = textStyle.copyWith(fontFeatures: [const FontFeature.superscripts()]);
          } else {
            textStyle = textStyle.copyWith(fontFeatures: [const FontFeature.subscripts()]);
          }
          break;
      }
    }
    return textStyle;
  }
}

List<List<dynamic>> romanNumeralSymbols = [
  ['m', 'cm', 'd', 'cd', 'c', 'xc', 'l', 'xl', 'x', 'ix', 'v', 'iv', 'i'],
  [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1]
];

extension Representation on int {
  String toRomanNumeral() {
    String result = '';
    int number = this;
    for (int i = 0; i < romanNumeralSymbols[0].length; i++) {
      while (number >= romanNumeralSymbols[1][i]) {
        result += romanNumeralSymbols[0][i];
        number -= romanNumeralSymbols[1][i] as int;
      }
    }
    return result;
  }
}
