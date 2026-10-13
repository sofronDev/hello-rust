import 'dart:js_interop';

import 'package:web/web.dart' as web;

web.AudioContext? _ctx;

/// Creates/resumes the audio context. Must run inside a user gesture so
/// iOS Safari allows the later beep.
void primeAlert() {
  try {
    final ctx = _ctx ??= web.AudioContext();
    if (ctx.state == 'suspended') ctx.resume();
  } catch (_) {}
}

/// Three short beeps and a vibration (where supported).
void restDoneAlert() {
  try {
    final ctx = _ctx ??= web.AudioContext();
    for (var i = 0; i < 3; i++) {
      final osc = ctx.createOscillator();
      final gain = ctx.createGain();
      osc.type = 'sine';
      osc.frequency.value = 880;
      final t = ctx.currentTime + i * 0.25;
      gain.gain.setValueAtTime(0.0001, t);
      gain.gain.exponentialRampToValueAtTime(0.35, t + 0.02);
      gain.gain.exponentialRampToValueAtTime(0.0001, t + 0.18);
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start(t);
      osc.stop(t + 0.2);
    }
  } catch (_) {}
  try {
    web.window.navigator.vibrate([200.toJS, 100.toJS, 200.toJS].toJS);
  } catch (_) {}
}
