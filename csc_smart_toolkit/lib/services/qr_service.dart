import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// All supported QR content types
enum QRType { text, url, phone, email, wifi, contact }

extension QRTypeLabel on QRType {
  String get label {
    switch (this) {
      case QRType.text:    return 'Text';
      case QRType.url:     return 'URL';
      case QRType.phone:   return 'Phone';
      case QRType.email:   return 'Email';
      case QRType.wifi:    return 'WiFi';
      case QRType.contact: return 'Contact';
    }
  }
}

/// WiFi authentication modes
enum WifiAuth { wpa, wep, nopass }

/// Builds the QR payload string from structured fields.
class QRService {
  QRService._();

  /// Build a QR value string for the given [type] and field map.
  static String buildValue(QRType type, Map<String, String> fields) {
    switch (type) {
      case QRType.text:
        return fields['text'] ?? '';
      case QRType.url:
        final url = fields['url'] ?? '';
        if (url.isEmpty) return '';
        if (!url.startsWith('http://') && !url.startsWith('https://')) {
          return 'https://$url';
        }
        return url;
      case QRType.phone:
        final phone = fields['phone'] ?? '';
        if (phone.isEmpty) return '';
        return 'tel:$phone';
      case QRType.email:
        final email  = fields['email']   ?? '';
        final subject = fields['subject'] ?? '';
        final body    = fields['body']    ?? '';
        if (email.isEmpty) return '';
        final params = <String>[];
        if (subject.isNotEmpty) params.add('subject=${Uri.encodeComponent(subject)}');
        if (body.isNotEmpty)    params.add('body=${Uri.encodeComponent(body)}');
        return params.isEmpty ? 'mailto:$email' : 'mailto:$email?${params.join('&')}';
      case QRType.wifi:
        final ssid     = fields['ssid']     ?? '';
        final password = fields['password'] ?? '';
        final auth     = fields['auth']     ?? 'WPA';
        if (ssid.isEmpty) return '';
        return 'WIFI:T:$auth;S:$ssid;P:$password;;';
      case QRType.contact:
        final name    = fields['name']    ?? '';
        final phone   = fields['phone']   ?? '';
        final email   = fields['email']   ?? '';
        final org     = fields['org']     ?? '';
        final address = fields['address'] ?? '';
        final buf = StringBuffer('BEGIN:VCARD\nVERSION:3.0\n');
        if (name.isNotEmpty)    buf.writeln('FN:$name');
        if (phone.isNotEmpty)   buf.writeln('TEL:$phone');
        if (email.isNotEmpty)   buf.writeln('EMAIL:$email');
        if (org.isNotEmpty)     buf.writeln('ORG:$org');
        if (address.isNotEmpty) buf.writeln('ADR:;;$address;;;;');
        buf.write('END:VCARD');
        return buf.toString();
    }
  }

  /// Returns a short human-readable description of the QR value type.
  static String describe(QRType type, Map<String, String> fields) {
    switch (type) {
      case QRType.text:    return fields['text']  ?? 'Text';
      case QRType.url:     return fields['url']   ?? 'URL';
      case QRType.phone:   return fields['phone'] ?? 'Phone';
      case QRType.email:   return fields['email'] ?? 'Email';
      case QRType.wifi:    return fields['ssid']  ?? 'WiFi';
      case QRType.contact: return fields['name']  ?? 'Contact';
    }
  }

  /// Detect QR result type from scanned string.
  static String detectType(String value) {
    if (value.startsWith('tel:'))                         return 'Phone';
    if (value.startsWith('mailto:'))                      return 'Email';
    if (value.startsWith('WIFI:'))                        return 'WiFi';
    if (value.startsWith('BEGIN:VCARD'))                  return 'Contact';
    if (value.startsWith('http://') ||
        value.startsWith('https://'))                     return 'URL';
    if (value.startsWith('geo:'))                         return 'Location';
    return 'Text';
  }

  // ── Export helpers ─────────────────────────────────────────────────────────

  /// Capture a [RepaintBoundary] key as PNG bytes.
  static Future<Uint8List> captureWidget(GlobalKey key,
      {double pixelRatio = 3.0}) async {
    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  /// Wrap PNG bytes into a single-page PDF.
  static Future<Uint8List> pngToPdf(Uint8List pngBytes,
      {double pageWidthPt = 300, double pageHeightPt = 300}) async {
    final doc = pw.Document();
    final img = pw.MemoryImage(pngBytes);
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(pageWidthPt, pageHeightPt),
        margin: const pw.EdgeInsets.all(16),
        build: (ctx) => pw.Center(
          child: pw.Image(img, fit: pw.BoxFit.contain),
        ),
      ),
    );
    return doc.save();
  }
}
