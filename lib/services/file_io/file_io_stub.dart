const bool fileIoSupported = false;

void downloadText(String filename, String text) =>
    throw UnsupportedError('File download is only available on the web');

Future<String?> pickTextFile() async => null;
