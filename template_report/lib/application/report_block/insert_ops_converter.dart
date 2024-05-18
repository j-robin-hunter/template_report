import 'package:collection/collection.dart';
import 'package:template_report/application/report_block/value_types.dart';

import 'delta_insert_op.dart';
import 'helpers/truthy.dart';
import 'insert_data.dart';
import 'insert_op_denormalizer.dart';
import 'op_attribute_sanitizer.dart';

/// Converts raw delta insert ops to array of denormalized DeltaInsertOp objects.
class InsertOpsConverter {
  static List<DeltaInsertOp> convert(
      List<Map<String, dynamic>>? deltaOps,
      OpAttributeSanitizerOptions options,
      ) {
    if (deltaOps == null) {
      return [];
    }

    final denormalizedOps = deltaOps.map(InsertOpDenormalizer.denormalize).flattened.toList();
    final results = <DeltaInsertOp>[];

    for (final op in denormalizedOps) {
      final rawInsertValue = op['insert'];
      if (!isTruthy(rawInsertValue)) {
        continue;
      }

      final insertVal = InsertOpsConverter.convertInsertVal(rawInsertValue, options);
      if (insertVal == null) {
        continue;
      }

      final rawAttributes = op['attributes'];
      final attributes = rawAttributes == null ? null : OpAttributeSanitizer.sanitize(OpAttributes()..attrs.addAll(rawAttributes), options);

      results.add(DeltaInsertOp(insertVal, attributes));
    }

    return results;
  }

  static InsertData? convertInsertVal(dynamic insertPropVal, OpAttributeSanitizerOptions sanitizeOptions) {
    if (insertPropVal is String) {
      return InsertDataQuill(DataType.text, insertPropVal);
    }

    if (!isTruthy(insertPropVal) || insertPropVal is! Map<String, dynamic>) {
      return null;
    }

    final keys = insertPropVal.keys.toList(growable: false);
    if (keys.isEmpty) {
      return null;
    }

    if (keys.contains(DataType.image.value)) {
      return InsertDataQuill(DataType.image, insertPropVal[DataType.image.value]);
    }

    if (keys.contains(DataType.video.value)) {
      return InsertDataQuill(DataType.video, insertPropVal[DataType.video.value]);
    }

    if (keys.contains(DataType.formula.value)) {
      return InsertDataQuill(DataType.formula, insertPropVal[DataType.formula.value]);
    }

    // custom
    final firstKey = keys.first;
    return InsertDataCustom(firstKey, insertPropVal[firstKey]);
  }
}