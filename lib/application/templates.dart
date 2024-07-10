// ************************************************************
//
// Copyright 2024 Robin Hunter rhunter@crml.com
// All rights reserved
//
// This work must not be copied, used or derived from either
// or via any medium without the express written permission
// and license from the owner
//
// ************************************************************
import 'package:flutter_quill/quill_delta.dart';

class Template {
  String? id;
  String? name;
  String? description;
  Delta? delta;

  Template({
    this.id,
    this.name,
    this.description,
    delta,
  }) {
    this.delta = delta ?? Delta.fromOperations([Operation.insert('\n')]);
  }

  factory Template.fromJson(Map<String, dynamic> json) {
    List<Operation> operations = [];
    for (var operation in json['delta']) {
      Map<String, dynamic>? attrMap;
      if (operation['attributes'] != null && operation['attributes'].isNotEmpty) {
        attrMap = {};
        String attributes = operation['attributes'].replaceAll('{', '').replaceAll('}', '').replaceAll(' ', '');
        for (final attr in attributes.split(',')) {
          List keyValue = attr.split(':');
          if (double.tryParse(keyValue[1]) != null) {
            attrMap[keyValue[0]] = double.parse(keyValue[1]);
          } else if (keyValue[1] == 'true' || keyValue[1] == 'false') {
            attrMap[keyValue[0]] = keyValue[1] == 'true' ? true : false;
          } else {
            attrMap[keyValue[0]] = "${keyValue[1]}";
          }
        }
      }
      if (operation['data'].contains('custom:')) {
        // Extract the custom embed from the saved data and create an Operation from it
        RegExp regExp = RegExp(r'\{[^{]*(?=})');
        Match? match = regExp.firstMatch(operation['data']);
        if (match != null) {
          operations.add(Operation.insert({"custom": match[0]!.replaceAll("'", '"')}, attrMap));
        } else {
          operations.add(Operation.insert(operation['data'], attrMap));
        }
      } else {
        operations.add(Operation.insert(operation['data'], attrMap));
      }
    }
    return Template(
      id: json['id'] as String?,
      name: json['name'] as String?,
      description: json['description'] as String?,
      delta: Delta.fromOperations(operations),
    );
  }

  String toGraphQL(String clientId) => '''
  {
    clientId: "$clientId"
    name: "$name"
    description: ${description != null ? '"$description"' : null}
    delta: [${deltaToGraphQL()}]
  }
  ''';

  String deltaToGraphQL() {
    String graphql = '';
    for (final operation in delta?.operations ?? []) {
      if (operation.data.runtimeType == String) {
        graphql = '$graphql{data: "${operation.data.replaceAll('"', "'").replaceAll('\n', '\\\\n')}"';
      } else {
        // Add inside <x></x>, which Deepl should be configured to ignore for translation
        graphql = '$graphql{data: "<x>${operation.data.toString().replaceAll('"', "'")}</x>"';
      }
      if (operation.attributes != null) {
        graphql = '$graphql attributes: "${operation.attributes.toString().replaceAll('{', '').replaceAll('}', '').replaceAll(' ', '')}"';
      }
      graphql = '$graphql}';
    }
    return graphql;
  }
}
