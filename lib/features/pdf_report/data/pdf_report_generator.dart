import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../report_problem/domain/entities/problem_report.dart';

/// Produces a branded, printable/shareable PDF for a single report —
/// the evidence document a citizen can hand to a local official or
/// carry to a complaint office. All values come directly from the
/// report's own recorded data; nothing is invented at export time —
/// any field the device/report doesn't have prints "Not available on
/// this device" rather than being silently omitted or guessed.
class PdfReportGenerator {
  /// [evidenceMeasurementCount] is how many of the citizen's own
  /// measurements support this report (the linked measurement, plus
  /// any other nearby ones the caller chooses to count — see
  /// `MyReportsScreen`). Pass 0/null if unknown; never fabricated.
  ///
  /// [mapSnapshotBytes], if provided by the caller (e.g. a
  /// `RenderRepaintBoundary` capture of the signal map widget), is
  /// embedded as the location evidence image. When omitted, the PDF
  /// explicitly states that a map snapshot is not included — it never
  /// silently drops this section or fabricates a map image.
  Future<Uint8List> generate(
    ProblemReport report, {
    int? evidenceMeasurementCount,
    Uint8List? mapSnapshotBytes,
  }) async {
    final doc = pw.Document();
    final dateFormat = DateFormat.yMMMMd().add_jm();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => context.pageNumber == 1
            ? pw.SizedBox()
            : pw.Text(
                'Darazinda Connect — Report ${report.id}',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              ),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'DARAZINDA CONNECT',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#0B5FA5'),
                    ),
                  ),
                  pw.Text(
                    'Tehsil Darazinda Slow Network — Connectivity '
                    'Evidence Report',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
              pw.Text(
                'Report ID\n${report.id}',
                textAlign: pw.TextAlign.right,
                style:
                    pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
          pw.Divider(thickness: 1, color: PdfColor.fromHex('#E1E8EF')),
          pw.SizedBox(height: 12),
          pw.Text('Report Details',
              style:
                  pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          _kv('Category', report.category.label),
          _kv('Status', report.status.label),
          _kv('Date / Time', dateFormat.format(report.createdAt)),
          _kv('Description', report.description ?? 'Not provided'),
          pw.SizedBox(height: 16),
          pw.Text('Location',
              style:
                  pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          _kv('GPS Coordinates',
              '${report.latitude.toStringAsFixed(6)}, '
                  '${report.longitude.toStringAsFixed(6)}'),
          _kv(
            'GPS Accuracy',
            report.gpsAccuracyMeters != null
                ? '±${report.gpsAccuracyMeters!.toStringAsFixed(0)} m'
                : 'Not available on this device',
          ),
          pw.SizedBox(height: 8),
          if (mapSnapshotBytes != null)
            pw.Container(
              height: 160,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColor.fromHex('#E1E8EF')),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.ClipRRect(
                horizontalRadius: 6,
                verticalRadius: 6,
                child: pw.Image(
                  pw.MemoryImage(mapSnapshotBytes),
                  fit: pw.BoxFit.cover,
                ),
              ),
            )
          else
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#F5F8FB'),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Text(
                'Map snapshot not available for this export.',
                style: const pw.TextStyle(
                    fontSize: 9, color: PdfColors.grey600),
              ),
            ),
          pw.SizedBox(height: 16),
          pw.Text('Network Evidence',
              style:
                  pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          _kv('Operator',
              report.operatorName ?? 'Not available on this device'),
          _kv('Network Type',
              report.networkType ?? 'Not available on this device'),
          _kv(
            'Signal Strength',
            report.signalDbm != null
                ? '${report.signalDbm} dBm'
                : 'Not available on this device',
          ),
          _kv(
            'Download Speed',
            report.downloadMbps != null
                ? '${report.downloadMbps!.toStringAsFixed(1)} Mbps'
                : 'Not available on this device',
          ),
          _kv(
            'Upload Speed',
            report.uploadMbps != null
                ? '${report.uploadMbps!.toStringAsFixed(1)} Mbps'
                : 'Not available on this device',
          ),
          _kv(
            'Latency (Ping)',
            report.pingMs != null
                ? '${report.pingMs} ms'
                : 'Not available on this device',
          ),
          pw.SizedBox(height: 16),
          pw.Text('Evidence Summary',
              style:
                  pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          _kv(
            'Supporting Measurements',
            evidenceMeasurementCount != null && evidenceMeasurementCount > 0
                ? '$evidenceMeasurementCount'
                : 'None linked',
          ),
          _kv('Linked Measurement ID', report.linkedMeasurementId ?? 'None'),
          pw.SizedBox(height: 20),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#F5F8FB'),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Text(
              'This document is generated from data submitted by a '
              'community member through Darazinda Connect. It is '
              'evidence of a self-reported connectivity issue and does '
              'not constitute an official finding by any telecom '
              'operator or government authority unless separately '
              'verified. Darazinda Connect does not boost cellular '
              'signal — it measures and reports network conditions.',
              style: const pw.TextStyle(fontSize: 9),
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Divider(color: PdfColor.fromHex('#E1E8EF')),
          pw.Text(
            'Generated by Darazinda Connect on '
            '${dateFormat.format(DateTime.now())}',
            style:
                const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _kv(String key, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 150,
            child: pw.Text(key,
                style: const pw.TextStyle(
                    fontSize: 10, color: PdfColors.grey700)),
          ),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
          ),
        ],
      ),
    );
  }
}
