import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import 'package:bump/data/models/prospect_model.dart';

class ExportService {
  /// Generates a CSV string from a list of prospects.
  String exportProspectsToCSV(List<Prospect> prospects) {
    final header = [
      'Name',
      'Email',
      'Phone',
      'Company',
      'Title',
      'Status',
      'Exchange Method',
      'Exchange Time',
      'Event',
      'Tags',
      'Notes',
    ];

    final rows = prospects.map((p) {
      return [
        '${p.firstName} ${p.lastName}'.trim(),
        p.email,
        p.phone,
        p.company,
        p.title,
        p.status.displayName,
        p.exchangeMethod.displayName,
        DateFormat('yyyy-MM-dd HH:mm').format(p.exchangeTime),
        p.eventId,
        p.tags.join(', '),
        p.notes,
      ];
    }).toList();

    const converter = ListToCsvConverter();
    return converter.convert([header, ...rows]);
  }

  /// Saves CSV data to the app-private directory, shares it, then deletes it.
  Future<void> saveAndShareCSV(String csvData, String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(csvData);

    try {
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: filename,
      );
    } finally {
      // Always clean up PII-containing file after sharing completes
      if (await file.exists()) {
        await file.delete();
      }
    }
  }
}
