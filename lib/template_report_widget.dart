/*
 * Copyright (c) 2024 Robin Hunter rhunter@crml.com
 *  All rights reserved
 *
 * This work must not be copied, used or derived from either
 * or via any medium without the express written permission
 * and license from the owner
 */
library template_report;

import 'package:flutter/material.dart';

import 'application/report_block/group_to_widget_converter.dart';
import 'application/report_block/op_attribute_sanitizer.dart';
import 'application/report_block/quill_delta_to_widgets_converter.dart';
import 'application/templates.dart';

class TemplateReportWidget extends StatelessWidget {
  final Template? template;
  final TextDirection textDirection;

  const TemplateReportWidget({
    required this.template,
    this.textDirection = TextDirection.ltr,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: textDirection,
      child: ListView(
        shrinkWrap: true,
        children: template != null ? getReport(template!) : [],
      ),
    );
  }

  List<Widget> getReport(Template template) {
    QuillDeltaToWidgetsConverter converter = QuillDeltaToWidgetsConverter(
      List.castFrom(template.delta!.toJson()),
      ConverterOptions(
        converterOptions: OpConverterOptions(
          indentPixels: 40,
        ),
        sanitizerOptions: OpAttributeSanitizerOptions(
          allow8DigitHexColors: true,
        ),
      ),
    );
    return converter.convert();
  }
}

