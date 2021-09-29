import 'dart:convert';
import 'package:args/args.dart';
import 'package:assignment1/reciever-process.dart';
import 'dart:io';

import 'package:assignment1/sender-process.dart';

void main(List<String> arguments) async {
  exitCode = 0;
  final parser = ArgParser();
  parser.addCommand('send');
  parser.addCommand('recieve');
  parser.addOption('port',
      abbr: 'p', help: 'The port for the pub/sub protocol', mandatory: true);

  var argResults = parser.parse(arguments);
  late int port;
  try {
    if (argResults.wasParsed('port')) {
      port = int.parse(argResults['port']);
      assert(port is int);
    } else {
      throw ArgumentError.value(argResults['port'] + ' is not a valid port');
    }
    if (argResults.command!.name == 'send' &&
        argResults.command!.name == 'recieve') {
      exitCode = 2;
      throw ArgumentError('Exception: conflicting arguments provided');
    } else if (arguments.contains('send')) {
      await stdin.forEach((element) async {
        var message = Utf8Codec().decode(element);
        await SenderProcess.sendStringMessage(message, port);
      });
    } else if (arguments.contains('recieve')) {
      await RecieverProcess.createReacieverProcess(port: port)
          .then((value) => print('Reciever process created on ip'));
    }
  } on ArgumentError catch (e) {
    stderr.writeln(e.toString() + '\n    ' + e.message.toString());
  } catch (e) {
    stderr.writeln(e);
  }
}
