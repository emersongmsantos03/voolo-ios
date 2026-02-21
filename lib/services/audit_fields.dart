import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/v2/enums.dart';

Map<String, dynamic> createAuditFields({
  required String createdBy,
  required String sourceApp,
}) {
  return {
    'schemaVersion': SchemaVersion.v2,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
    'createdBy': createdBy,
    'sourceApp': sourceApp,
  };
}

Map<String, dynamic> updateAuditFields() {
  return {
    'updatedAt': FieldValue.serverTimestamp(),
  };
}

