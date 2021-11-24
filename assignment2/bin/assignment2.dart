import 'dart:io';

import 'package:args/args.dart';

import 'controller.dart';
import 'element.dart';
import 'forwarding_service.dart';
import 'router.dart';

void main(List<String> arguments) async {
  exitCode = 0;
  final parser = ArgParser();
  parser.addCommand('controller');
  parser.addCommand('router');
  parser.addCommand('element');
  parser.addCommand('forward');
  parser.addFlag('send', abbr: 's');
  parser.addFlag('recieve', abbr: 'r');

  var argResults = parser.parse(arguments);
  try {
    if (argResults.command!.name == 'controller') {
      Controller controller = Controller();
      print('Starting controller process');
      await controller.control();
    } else if (argResults.command!.name == 'router') {
      Router router = Router();
      print('start router process');
      await router.routerProcess();
    } else if (argResults.command!.name == 'element') {
      if (argResults.wasParsed('send')) {
        Element sender = Element();
        print('starting sender process');
        Future.delayed(Duration(seconds: 2))
            .then((value) async => await sender.send());
      } else if (argResults.wasParsed('recieve')) {
        Element reciever = Element();
        print('starting reciever process');
        await reciever.recieve();
      }
    } else if (argResults.command!.name == 'forward') {
      ForwardingService forwardingService = ForwardingService();
      print('Starting forwarding service');
      await forwardingService.forwardingProcess();
    }
  } catch (e, s) {
    exitCode = 2;
    stderr.addError(e, s);
  }
}
