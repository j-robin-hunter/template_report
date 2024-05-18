/*
 * Copyright (c) 2024 Robin Hunter rhunter@crml.com
 *  All rights reserved
 *
 * This work must not be copied, used or derived from either
 * or via any medium without the express written permission
 * and license from the owner
 *
 * This is a partial port of the flutter package vsc_quill_delta_to_html
 */
import 'package:flutter/material.dart';

import 'group_to_widget_converter.dart';
import 'grouper/group_types.dart';
import 'grouper/grouper.dart';
import 'grouper/list_nester.dart';
import 'grouper/table_grouper.dart';
import 'insert_ops_converter.dart';
import 'op_attribute_sanitizer.dart';


class QuillDeltaToWidgetsConverter {
  final List<Map<String, dynamic>> _rawDeltaOps;
  late ConverterOptions _options;
  late OpConverterOptions _converterOptions;

  QuillDeltaToWidgetsConverter(this._rawDeltaOps, [ConverterOptions? options]) {
    _options = options ?? ConverterOptions();
    _converterOptions = _options.converterOptions;
  }

  List<TDataGroup> getGroupedOps() {
    var deltaOps = InsertOpsConverter.convert(_rawDeltaOps, _options.sanitizerOptions);
    var pairedOps = Grouper.pairOpsWithTheirBlock(deltaOps);

    var groupedSameStyleBlocks = Grouper.groupConsecutiveSameStyleBlocks(
      pairedOps,
    );

    var groupedOps = Grouper.reduceConsecutiveSameStyleBlocksToOne(groupedSameStyleBlocks);

    groupedOps = TableGrouper().group(groupedOps);
    return ListNester().nest(groupedOps);
  }

  List<Widget> convert() {
    final groups = getGroupedOps();
    return groups.map((group) {
      final converter = GroupToWidgetConverter(group, _converterOptions);
      return converter.getWidget();
    }).toList();
  }
}

class ConverterOptions {
  late OpAttributeSanitizerOptions sanitizerOptions;
  late OpConverterOptions converterOptions;

  ConverterOptions({
    OpAttributeSanitizerOptions? sanitizerOptions,
    OpConverterOptions? converterOptions,
  }) {
    this.sanitizerOptions = sanitizerOptions ?? OpAttributeSanitizerOptions();
    this.converterOptions = converterOptions ?? OpConverterOptions();
    _initCommon();
  }

  void _initCommon() {
  }
}