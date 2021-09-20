import 'dart:io';

String calculate() {
  return File('foo.txt').readAsBytes().toString();
}
