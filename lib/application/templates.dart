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
import 'dart:convert';
import 'package:yaml/yaml.dart';
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

      // Use try/catch to decode data.
      try {
        YamlMap yamlMap = loadYaml(operation['data'].replaceAll(':', ': ').replaceAll(RegExp(r'</?x>'), ''));
        //operations.add(Operation.insert({"custom": '{"${yamlMap['custom'].keys.first}": "\\"${yamlMap['custom'].values.first}\\""}'}, attrMap));
        print({"custom": '{"${yamlMap['custom'].keys.first}": "\\"${yamlMap['custom'].values.first}\\""}'});
        String data = operation['data'].replaceAll(RegExp(r'</?x>'), '');
        data = data.replaceAll(RegExp(r'\s'), '');
        data = data.replaceAll(RegExp(r'[{}]'), '');
        data = data.replaceAll('\'', '\\"');
        List parts = data.split(':');
        print({"${parts[0]}":'{"${parts[1]}":"\\\\"${parts[2]}\\\\""}'});
        operations.add(Operation.insert({"${parts[0]}":'{"${parts[1]}":"${parts[2]}"}'}, attrMap));
      } catch(e) {
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
        graphql = '$graphql{data: "${operation.data.replaceAll('"', "'").replaceAll('\n', r'\\n')}"';
      } else {
        try {
          final Map custom = jsonDecode(operation.data['custom']);
          final List entries = custom.entries.toList();
          graphql = '$graphql{data:"<x>{custom:{${entries.first.key}:${entries.first.value.replaceAll('"', "'")}}}</x>"';
        } catch (e) {
          // Do nothing
        }
      }
      if (operation.attributes != null) {
        graphql = '$graphql attributes: "${operation.attributes.toString().replaceAll('{', '').replaceAll('}', '').replaceAll(' ', '')}"';
      }
      graphql = graphql.isNotEmpty ? '$graphql}' : '';
    }
    return graphql;
  }
}
