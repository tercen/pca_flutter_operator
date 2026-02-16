import 'dart:js_interop';
import 'package:web/web.dart' as web;

/// Triggers a browser file download with the given content and filename.
/// WASM-compatible (uses package:web, not dart:html).
void downloadFile(String content, String filename) {
  final blob = web.Blob(
    [content.toJS].toJS,
    web.BlobPropertyBag(type: 'text/csv'),
  );
  final url = web.URL.createObjectURL(blob);

  final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
  anchor.href = url;
  anchor.download = filename;
  anchor.click();

  web.URL.revokeObjectURL(url);
}
