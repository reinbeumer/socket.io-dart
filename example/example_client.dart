import 'dart:io';

void main() {
  stdout.writeln('This package is server-only.');
  stdout.writeln('Use one of these client examples instead:');
  stdout.writeln('  - node example/example_client.js');
  stdout.writeln('  - open example/example_client.html');
  stdout.writeln('For transport smoke checks use:');
  stdout.writeln('  - dart run example/polling_smoke.dart');
}
