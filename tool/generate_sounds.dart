// Synthesises the app's sound effects as small WAV files, so no audio has to be
// downloaded or licensed and the sounds can be tuned by editing numbers here.
//
// Run from the project root:
//   dart run tool/generate_sounds.dart
//
// Output: assets/sounds/*.wav (44.1 kHz, 16-bit, mono).
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

const _sampleRate = 44100;

void main() {
  final out = Directory('assets/sounds')..createSync(recursive: true);

  // Short, soft UI sounds.
  _write(out, 'tap', _tap());
  _write(
    out,
    'toggle_on',
    _glide(from: 660, to: 990, seconds: 0.13, amp: 0.42),
  );
  _write(
    out,
    'toggle_off',
    _glide(from: 990, to: 600, seconds: 0.13, amp: 0.38),
  );
  _write(out, 'confirm', _notes([880, 1320], noteSeconds: 0.11, amp: 0.45));

  // Alert sounds, designed to loop cleanly (they end in silence).
  _write(out, 'alarm', _alarm());
  _write(
    out,
    'timer_done',
    _notes(
      [784, 988, 1175, 0, 784, 988, 1175],
      noteSeconds: 0.32,
      amp: 0.6,
      tailSeconds: 0.9,
    ),
  );

  stdout.writeln('Wrote ${out.listSync().length} files to ${out.path}');
}

/// A short, dry "tick".
List<double> _tap() {
  final n = (0.045 * _sampleRate).round();
  return List.generate(n, (i) {
    final t = i / _sampleRate;
    final decay = math.exp(-t / 0.007);
    final tone =
        math.sin(2 * math.pi * 1500 * t) +
        0.5 * math.sin(2 * math.pi * 2250 * t);
    return 0.36 * decay * tone;
  });
}

/// A sine that glides from [from] to [to] Hz.
List<double> _glide({
  required double from,
  required double to,
  required double seconds,
  required double amp,
}) {
  final n = (seconds * _sampleRate).round();
  var phase = 0.0;
  return List.generate(n, (i) {
    final p = i / n;
    final freq = from + (to - from) * p;
    phase += 2 * math.pi * freq / _sampleRate;
    final envelope = math.sin(math.pi * p); // fade in and out
    return amp * envelope * math.sin(phase);
  });
}

/// Consecutive notes (0 = rest), each with a bell-like decay.
List<double> _notes(
  List<double> freqs, {
  required double noteSeconds,
  required double amp,
  double tailSeconds = 0.12,
}) {
  final samples = <double>[];
  final noteLen = (noteSeconds * _sampleRate).round();
  for (final f in freqs) {
    for (var i = 0; i < noteLen; i++) {
      final t = i / _sampleRate;
      if (f == 0) {
        samples.add(0);
        continue;
      }
      final decay = math.exp(-t / (noteSeconds * 0.55));
      final tone =
          math.sin(2 * math.pi * f * t) +
          0.25 * math.sin(2 * math.pi * f * 2 * t);
      samples.add(amp * decay * tone);
    }
  }
  samples.addAll(List.filled((tailSeconds * _sampleRate).round(), 0));
  return samples;
}

/// Four quick beeps followed by a pause: 1.6 seconds, loops seamlessly.
List<double> _alarm() {
  const period = 1.6;
  final samples = List<double>.filled((period * _sampleRate).round(), 0);
  for (var beep = 0; beep < 4; beep++) {
    final start = (beep * 0.22 * _sampleRate).round();
    final len = (0.13 * _sampleRate).round();
    for (var i = 0; i < len; i++) {
      final t = i / _sampleRate;
      final p = i / len;
      final envelope = math.min(1.0, p * 12) * math.min(1.0, (1 - p) * 8);
      final tone =
          math.sin(2 * math.pi * 988 * t) +
          0.3 * math.sin(2 * math.pi * 1976 * t);
      samples[start + i] += 0.62 * envelope * tone;
    }
  }
  return samples;
}

void _write(Directory dir, String name, List<double> samples) {
  // Normalise only if something would clip; otherwise keep the designed level.
  final peak = samples.fold<double>(0, (m, s) => math.max(m, s.abs()));
  final gain = peak > 0.95 ? 0.95 / peak : 1.0;

  final data = ByteData(44 + samples.length * 2);
  void ascii(int offset, String s) {
    for (var i = 0; i < s.length; i++) {
      data.setUint8(offset + i, s.codeUnitAt(i));
    }
  }

  ascii(0, 'RIFF');
  data.setUint32(4, 36 + samples.length * 2, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  data.setUint32(16, 16, Endian.little); // PCM chunk size
  data.setUint16(20, 1, Endian.little); // PCM
  data.setUint16(22, 1, Endian.little); // mono
  data.setUint32(24, _sampleRate, Endian.little);
  data.setUint32(28, _sampleRate * 2, Endian.little); // byte rate
  data.setUint16(32, 2, Endian.little); // block align
  data.setUint16(34, 16, Endian.little); // bits per sample
  ascii(36, 'data');
  data.setUint32(40, samples.length * 2, Endian.little);
  for (var i = 0; i < samples.length; i++) {
    final v = (samples[i] * gain * 32767).round().clamp(-32768, 32767);
    data.setInt16(44 + i * 2, v, Endian.little);
  }

  File('${dir.path}/$name.wav').writeAsBytesSync(data.buffer.asUint8List());
}
