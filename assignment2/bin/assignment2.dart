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
      print('start router process');
      await router.forward();
    } else if (argResults.command!.name == 'element') {
      if (argResults.wasParsed('send')) {
        Element sender = Element();
        print('starting sender process');
        Future.delayed(Duration(seconds: 1))
            .then((value) async => await sender.send());
      } else if (argResults.wasParsed('recieve')) {
        Element reciever = Element();
        print('starting reciever process');
        await reciever.recieve();
      }
    }
  } catch (e, s) {
    exitCode = 2;
    stderr.addError(e, s);
  }
}
