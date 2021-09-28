import 'dart:convert';

import 'package:args/args.dart';
import 'package:assignment1/reciever-process.dart';
import 'dart:io';

import 'package:assignment1/sender-process.dart';

void main(List<String> arguments) {
  exitCode = 0;
  final parser = ArgParser();
  parser.addCommand('send');
  parser.addCommand('recieve');
  parser.addOption('port', abbr: 'p', help: 'The port for the pub/sub protocol', mandatory: true);

  var argResults = parser.parse(arguments);

  try {
    if () {
      
    }
    if (argResults.command!.name == 'send' &&
        argResults.command!.name == 'recieve') {
      exitCode = 2;
      throw ArgumentError('Exception: conflicting arguments provided');
    } else if (arguments.contains('send')) {
      stdin.forEach((element) async {
        var message = Utf8Codec().decode(element);
        await SenderProcess.sendStringMessage(message, 4444);
      });
    } else if (arguments.contains('recieve')) {
      RecieverProcess.createReacieverProcess(port: 4444)
          .then((value) => print('Reciever process ended'));
    }
  } on ArgumentError catch (e) {
    stderr.writeln(e.toString() + '\n    ' + e.message);
  }
}
