import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

final log = Logger('TaskManager');

void setupLogging() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    log.log(record.level, '${record.time}: ${record.message}');
  });
}

void showErrorSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    ),
  );
}

String getErrorMessage(dynamic error) {
  if (error is Exception) {
    return error.toString().replaceAll("Exception: ", "");
  }
  return "An unexpected error occurred";
}

