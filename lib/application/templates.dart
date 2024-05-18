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

class Templates {
  List<String>? allTemplateNames;
  List<Template>? templates;

  Templates({
    this.allTemplateNames,
    this.templates,
  });

  factory Templates.fromJson(Map<String, dynamic> json) {
    List<Template> templates = [];
    for (var template in json['templates']) {
      templates.add(Template.fromJson(template));
    }
    return Templates(
      allTemplateNames: json['allTemplateNames'].isEmpty ? [] : json['allTemplateNames'].cast<String>(),
      templates: templates,
    );
  }
}

class Template {
  String? id;
  String? clientId;
  String? name;
  Delta? delta;

  Template({
    this.id,
    this.clientId,
    this.name,
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
      operations.add(Operation.insert(operation['data'], attrMap));
    }
    return Template(
      id: json['id'] as String?,
      clientId: json['clientId'] as String?,
      name: json['name'] as String?,
      delta: Delta.fromOperations(operations),
    );
  }

  String toGraphQL() => '''
  template: {
    clientId: "$clientId"
    name: $name
    delta: [${deltaToGraphQL()}]
  }
  ''';

  String deltaToGraphQL() {
    String graphql = '';
    for (final operation in delta?.operations ?? []) {
      graphql = '$graphql{data: "${operation.data.replaceAll('{{', '[[').replaceAll('}}', ']]').replaceAll('\n', '\\\\n')}"';
      if (operation.attributes != null) {
        graphql = '$graphql attributes: "${operation.attributes.toString().replaceAll('{', '').replaceAll('}','').replaceAll(' ', '')}"';
      }
      graphql = '$graphql}';
    }
    return graphql;
  }
}