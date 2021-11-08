import 'dart:io';

import 'package:args/args.dart';

import 'element.dart';
import 'router.dart';

void main(List<String> arguments) async {
  exitCode = 0;
  final parser = ArgParser();
  parser.addCommand('controller');
  parser.addCommand('router');
  parser.addCommand('element');
  parser.addFlag('send', abbr: 's');
  parser.addFlag('recieve', abbr: 'r');

  var argResults = parser.parse(arguments);
  try {
    if (argResults.command!.name == 'controller') {
      throw UnimplementedError();
    } else if (argResults.command!.name == 'router') {
      Router router = Router();
      await router.forward();
    } else if (argResults.command!.name == 'element') {
      if (argResults.command!.arguments.contains('send')) {
        Element sender = Element();
        while (exitCode == 0) {
          Future.delayed(Duration(seconds: 1)).then(
              (value) async =>
                  await sender.send().then((value) => print('sender started')),
              onError: (e, s) {
            stderr.addError(e, s);
            exitCode = 2;
          });
        }
      } else if (argResults.command!.arguments.contains('recieve')) {
        Element reciever = Element();
        await reciever.recieve().then((value) => print('reciever started'));
      }
    }
  } catch (e, s) {
    exitCode = 2;
    stderr.addError(e, s);
  }
}
