// Web shim — operations are handled differently on web; provide stubs.
Future<String> copyFileToAppDir(String sourcePath, String fileName) async {
  // on web we don't copy filesystem files; return original path
  return sourcePath;
}

Future<void> deleteIfInAppDir(String filePath) async {
  // no-op on web
}
