import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

const bool fileIoSupported = true;

void downloadText(String filename, String text) {
  final blob = web.Blob(
    [text.toJS].toJS,
    web.BlobPropertyBag(type: 'application/json'),
  );
  final url = web.URL.createObjectURL(blob);
  final a = web.HTMLAnchorElement()
    ..href = url
    ..download = filename;
  web.document.body!.append(a);
  a.click();
  a.remove();
  web.URL.revokeObjectURL(url);
}

Future<String?> pickTextFile() {
  final completer = Completer<String?>();
  void done(String? value) {
    if (!completer.isCompleted) completer.complete(value);
  }

  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = '.json,application/json';

  void onChange(web.Event _) {
    final file = input.files?.item(0);
    if (file == null) {
      done(null);
      return;
    }
    final reader = web.FileReader();
    void onLoad(web.Event _) => done(reader.result.dartify() as String?);
    void onError(web.Event _) => done(null);
    reader.addEventListener('load', onLoad.toJS);
    reader.addEventListener('error', onError.toJS);
    reader.readAsText(file);
  }

  void onCancel(web.Event _) => done(null);

  input.addEventListener('change', onChange.toJS);
  input.addEventListener('cancel', onCancel.toJS);
  input.click();
  return completer.future;
}
