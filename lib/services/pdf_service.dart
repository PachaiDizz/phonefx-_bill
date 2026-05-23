import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/repair_record.dart';

class PdfService {
  static Future<File> generatePdf(RepairRecord repair) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencyFormat = NumberFormat.currency(symbol: 'RM ', decimalDigits: 2);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _buildHeader(repair),
          pw.SizedBox(height: 20),
          _buildCustomerInfo(repair, dateFormat),
          pw.SizedBox(height: 20),
          _buildDeviceInfo(repair),
          pw.SizedBox(height: 20),
          _buildIssuesList(repair),
          pw.SizedBox(height: 20),
          if (repair.repairNotes != null && repair.repairNotes!.isNotEmpty) ...[
            _buildRepairNotes(repair),
            pw.SizedBox(height: 20),
          ],
          if (repair.customerProvidedParts.isNotEmpty) ...[
            _buildCustomerParts(repair),
            pw.SizedBox(height: 20),
          ],
          _buildChecklist('Before Repair Checklist', repair.checklistBefore, PdfColors.purple),
          pw.SizedBox(height: 20),
          _buildChecklist('After Repair Checklist', repair.checklistAfter, PdfColors.teal),
          pw.SizedBox(height: 20),
          _buildWarrantyInfo(repair, dateFormat),
          pw.SizedBox(height: 20),
          _buildTotalAmount(repair, currencyFormat),
          pw.SizedBox(height: 30),
          _buildWarrantyVoidConditions(),
          pw.SizedBox(height: 30),
          _buildFooter(),
        ],
      ),
    );

    final output = await getApplicationDocumentsDirectory();
    final billTag = repair.billNumber ?? 'PFX-${repair.id!.toString().padLeft(4, '0')}';
    final fileName = 'PhoneFX_${billTag}.pdf';
    final file = File('${output.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  static pw.Widget _buildHeader(RepairRecord repair) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue800,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'PhoneFX+',
            style: pw.TextStyle(
              fontSize: 32,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
          pw.Text(
            'Professional Repair Services',
            style: const pw.TextStyle(
              fontSize: 14,
              color: PdfColors.white,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Bill No: ${repair.billNumber ?? 'PFX-${repair.id!.toString().padLeft(4, '0')}'}',
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColors.white,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildCustomerInfo(RepairRecord repair, DateFormat dateFormat) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Customer Information',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Customer Name:', style: const pw.TextStyle(fontSize: 12)),
              pw.Text(repair.customerName, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Repair Date:', style: const pw.TextStyle(fontSize: 12)),
              pw.Text(dateFormat.format(repair.repairDate), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  static String _displayDeviceType(String type) {
    switch (type) {
      case 'Phone':
        return 'Smartphone';
      case 'PC':
        return 'Desktop PC';
      default:
        return type;
    }
  }

  static pw.Widget _buildDeviceInfo(RepairRecord repair) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Device Information',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Device Type:', style: const pw.TextStyle(fontSize: 12)),
              pw.Text(_displayDeviceType(repair.deviceType), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Device Brand:', style: const pw.TextStyle(fontSize: 12)),
              pw.Text(repair.deviceBrand, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Device Model:', style: const pw.TextStyle(fontSize: 12)),
              pw.Text(repair.deviceModel, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildIssuesList(RepairRecord repair) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Repairs / Issues',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 10),
          ...repair.issues.map((issue) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 5),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 10,
                  height: 10,
                  decoration: pw.BoxDecoration(
                    color: _getIssueIconColor(issue),
                    shape: pw.BoxShape.circle,
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Text(issue, style: const pw.TextStyle(fontSize: 12)),
                ),
              ],
            ),
          )),
          if (repair.customIssue != null && repair.customIssue!.isNotEmpty && !repair.issues.contains(repair.customIssue))
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 5),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: 10,
                    height: 10,
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blueGrey,
                      shape: pw.BoxShape.circle,
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Expanded(
                    child: pw.Text('Custom: ${repair.customIssue}', style: const pw.TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static PdfColor _getIssueIconColor(String issue) {
    final i = issue.toLowerCase();
    if (i.startsWith('screen') || i.startsWith('display') || i.startsWith('ghost') ||
        i.startsWith('lcd') || i.contains('backlight') || i.contains('dead pixel') ||
        i.contains('burn-in') || i.contains('monitor')) {
      return PdfColors.indigo;
    }
    if (i.startsWith('battery') || i.startsWith('charging') || i.startsWith('overheat') ||
        i.startsWith('boot') || i.startsWith('no power') || i.startsWith('power') ||
        i.startsWith('charg')) {
      return PdfColors.orange;
    }
    if (i.contains('water') || i.contains('liquid')) {
      return PdfColors.blue;
    }
    if (i.startsWith('motherboard') || i.startsWith('cpu') || i.startsWith('gpu') ||
        i.startsWith('graphics')) {
      return PdfColors.purple;
    }
    if (i.startsWith('disc') || i.startsWith('hdmi') || i.startsWith('controller') ||
        i.startsWith('trigger') || i.contains('console')) {
      return PdfColors.cyan;
    }
    if (i.startsWith('cooling') || i.startsWith('fan') || i.contains('thermal')) {
      return PdfColors.teal;
    }
    if (i.startsWith('speaker') || i.startsWith('microphone') || i.contains('audio')) {
      return PdfColors.pink;
    }
    if (i.startsWith('camera') || i.startsWith('webcam')) {
      return PdfColors.brown;
    }
    if (i.startsWith('network') || i.startsWith('wi-fi') || i.startsWith('hotspot') ||
        i.startsWith('cellular') || i.startsWith('gps') || i.startsWith('nfc') ||
        i.contains('signal')) {
      return PdfColors.green;
    }
    if (i.startsWith('bluetooth')) {
      return PdfColors.blue700;
    }
    if (i.startsWith('icloud') || i.startsWith('google') || i.startsWith('passcode') ||
        i.startsWith('activation') || i.startsWith('imei') || i.startsWith('password') ||
        i.startsWith('account')) {
      return PdfColors.red;
    }
    if (i.startsWith('data') || i.startsWith('storage') || i.startsWith('ram')) {
      return PdfColors.blueGrey;
    }
    if (i.startsWith('keyboard') || i.startsWith('trackpad')) {
      return PdfColors.grey700;
    }
    return PdfColors.grey600;
  }

  static pw.Widget _buildRepairNotes(RepairRecord repair) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.indigo),
        borderRadius: pw.BorderRadius.circular(8),
        color: PdfColors.indigo50,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Repair Notes',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.indigo800,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              repair.repairNotes!,
              style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildCustomerParts(RepairRecord repair) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.orange),
        borderRadius: pw.BorderRadius.circular(8),
        color: PdfColors.orange50,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Customer Provided Parts',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.orange800,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.red50,
              borderRadius: pw.BorderRadius.circular(4),
              border: pw.Border.all(color: PdfColors.red200),
            ),
            child: pw.Text(
              'No warranty coverage for customer-provided parts.',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.red700),
            ),
          ),
          pw.SizedBox(height: 10),
          ...repair.customerProvidedParts.map((part) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Row(
              children: [
                pw.Text('• ', style: const pw.TextStyle(fontSize: 11, color: PdfColors.orange800)),
                pw.Text(part, style: const pw.TextStyle(fontSize: 11)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  static pw.Widget _buildWarrantyInfo(RepairRecord repair, DateFormat dateFormat) {
    final isNoWarranty = repair.warrantyPeriod == 'No Warranty';
    final isExpired = isNoWarranty ? false : repair.warrantyExpiryDate.isBefore(DateTime.now());
    
    final borderColor = isNoWarranty ? PdfColors.grey : (isExpired ? PdfColors.red : PdfColors.green);
    final bgColor = isNoWarranty ? PdfColors.grey50 : (isExpired ? PdfColors.red50 : PdfColors.green50);
    final textColor = isNoWarranty ? PdfColors.grey700 : (isExpired ? PdfColors.red800 : PdfColors.green800);
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: borderColor, width: 2),
        borderRadius: pw.BorderRadius.circular(8),
        color: bgColor,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Warranty Information',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: textColor),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Warranty Period:', style: const pw.TextStyle(fontSize: 12)),
              pw.Text(repair.warrantyPeriod, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.SizedBox(height: 5),
          if (!isNoWarranty)
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Warranty Valid Until:', style: const pw.TextStyle(fontSize: 12)),
                pw.Text(
                  dateFormat.format(repair.warrantyExpiryDate),
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: isExpired ? PdfColors.red : PdfColors.green800),
                ),
              ],
            ),
          if (isNoWarranty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 5),
              child: pw.Text(
                'No warranty provided',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
              ),
            )
          else if (isExpired)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 5),
              child: pw.Text(
                'Warranty has expired',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.red),
              ),
            ),
        ],
      ),
    );
  }

  static pw.Widget _buildTotalAmount(RepairRecord repair, NumberFormat currencyFormat) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue800,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Total Amount:',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
          pw.Text(
            currencyFormat.format(repair.totalAmount),
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildChecklist(String title, Map<String, String> checklist, PdfColor accentColor) {
    if (checklist.isEmpty) {
      return pw.SizedBox();
    }

    final items = checklist.entries.toList();
    final passed = items.where((e) => e.value == 'pass').length;
    final failed = items.where((e) => e.value == 'fail').length;

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: accentColor),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: accentColor,
                ),
              ),
              pw.Text(
                '$passed Pass · $failed Fail',
                style: pw.TextStyle(
                  fontSize: 11,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          ...items.map((entry) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Row(
              children: [
                pw.Container(
                  width: 12,
                  height: 12,
                  decoration: pw.BoxDecoration(
                    color: entry.value == 'pass'
                        ? PdfColors.green
                        : PdfColors.red,
                    shape: pw.BoxShape.circle,
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: pw.Text(
                    entry.key,
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  static pw.Widget _buildWarrantyVoidConditions() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.red400),
        borderRadius: pw.BorderRadius.circular(8),
        color: PdfColors.red50,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Warranty Void Conditions',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.red800,
            ),
          ),
          pw.SizedBox(height: 10),
          ...DeviceIssues.warrantyVoidConditions.map((condition) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 3),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('• ', style: const pw.TextStyle(fontSize: 10, color: PdfColors.red700)),
                pw.Expanded(
                  child: pw.Text(condition, style: const pw.TextStyle(fontSize: 10, color: PdfColors.red700)),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey400),
        pw.SizedBox(height: 10),
        pw.Text(
          'Thank you for choosing PhoneFX+ for your repair needs!',
          style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'For warranty claims, please bring this receipt within the warranty period.',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Generated on: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey400),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }
}