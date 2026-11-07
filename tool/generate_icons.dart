// Regenerates the launcher icons from the in-app logo (LogoPainter), so the
// app icon and the logo in the UI always match. No extra packages needed.
//
// Run from the project root:
//   flutter test tool/generate_icons.dart
//
// It runs under `flutter test` only because that provides dart:ui rendering.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:ai_clock_1/core/widgets/app_logo.dart';
import 'package:flutter_test/flutter_test.dart';

const _androidRes = 'android/app/src/main/res';
const _iosIcons = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';

void main() {
  test('generate launcher icons', () async {
    // Android legacy icons (rounded badge), used below API 26.
    const legacy = {
      'mdpi': 48,
      'hdpi': 72,
      'xhdpi': 96,
      'xxhdpi': 144,
      'xxxhdpi': 192,
    };
    for (final e in legacy.entries) {
      await _write(
        '$_androidRes/mipmap-${e.key}/ic_launcher.png',
        e.value,
        const LogoPainter(background: LogoBackground.rounded),
      );
    }

    // Android adaptive-icon foreground: glyph only, shrunk into the safe zone.
    const adaptive = {
      'mdpi': 108,
      'hdpi': 162,
      'xhdpi': 216,
      'xxhdpi': 324,
      'xxxhdpi': 432,
    };
    for (final e in adaptive.entries) {
      await _write(
        '$_androidRes/mipmap-${e.key}/ic_launcher_foreground.png',
        e.value,
        const LogoPainter(background: LogoBackground.none, glyphScale: 0.72),
      );
    }

    // iOS: every size listed in the asset catalog. Opaque, no alpha channel.
    final contents = jsonDecode(
      File('$_iosIcons/Contents.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    for (final image in contents['images'] as List<dynamic>) {
      final size = double.parse((image['size'] as String).split('x').first);
      final scale = int.parse((image['scale'] as String).replaceAll('x', ''));
      await _write(
        '$_iosIcons/${image['filename']}',
        (size * scale).round(),
        const LogoPainter(background: LogoBackground.square),
        alpha: false,
      );
    }
  });
}

Future<void> _write(
  String path,
  int px,
  LogoPainter painter, {
  bool alpha = true,
}) async {
  final recorder = ui.PictureRecorder();
  painter.paint(ui.Canvas(recorder), ui.Size.square(px.toDouble()));
  final image = await recorder.endRecording().toImage(px, px);
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(_encodePng(px, px, data!.buffer.asUint8List(), alpha));
}

/// Minimal PNG encoder (8-bit RGB or RGBA, no filtering).
Uint8List _encodePng(int w, int h, Uint8List rgba, bool alpha) {
  final channels = alpha ? 4 : 3;
  final stride = w * channels + 1;
  final raw = Uint8List(stride * h);
  for (var y = 0; y < h; y++) {
    final row = y * stride;
    for (var x = 0; x < w; x++) {
      final src = (y * w + x) * 4;
      final dst = row + 1 + x * channels;
      for (var c = 0; c < channels; c++) {
        raw[dst + c] = rgba[src + c];
      }
    }
  }

  final out = BytesBuilder();
  out.add(const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
  void chunk(String type, List<int> data) {
    final body = [...ascii.encode(type), ...data];
    out
      ..add(_u32(data.length))
      ..add(body)
      ..add(_u32(_crc32(body)));
  }

  chunk('IHDR', [..._u32(w), ..._u32(h), 8, alpha ? 6 : 2, 0, 0, 0]);
  chunk('IDAT', ZLibCodec().encode(raw));
  chunk('IEND', const []);
  return out.toBytes();
}

List<int> _u32(int v) => [
  (v >> 24) & 0xFF,
  (v >> 16) & 0xFF,
  (v >> 8) & 0xFF,
  v & 0xFF,
];

int _crc32(List<int> bytes) {
  var crc = 0xFFFFFFFF;
  for (final b in bytes) {
    crc ^= b;
    for (var k = 0; k < 8; k++) {
      crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xEDB88320 : crc >> 1;
    }
  }
  return crc ^ 0xFFFFFFFF;
}
