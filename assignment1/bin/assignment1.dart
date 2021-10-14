import 'dart:convert';
import 'package:args/args.dart';
import 'package:assignment1/publisher.dart';
import 'package:assignment1/subscriber.dart';
import 'dart:io';

import 'package:assignment1/broker.dart';

void main(List<String> arguments) async {
  exitCode = 0;
  final parser = ArgParser();
  parser.addCommand('broker');
  parser.addCommand('sub');
  parser.addCommand('pub');
  parser.addOption('brokerip', abbr: 'b', help: 'The broker IPv4 Address');
  parser.addOption('port',
      abbr: 'p', help: 'The port for the pub/sub protocol', mandatory: true);

  var argResults = parser.parse(arguments);
  late int port;
  late InternetAddress brokerIP;
  try {
    if (argResults.wasParsed('port')) {
      port = int.parse(argResults['port']);
      assert(port is int);
    } else {
      throw ArgumentError.value(argResults['port'] + ' is not a valid port');
    }
    // prevent clashing commands
    if ((argResults.command!.name == 'pub' &&
            argResults.command!.name == 'sub') ||
        (argResults.command!.name == 'pub' &&
            (argResults.command!.name == 'broker' ||
                argResults.command!.name == 'sub'))) {
      exitCode = 2;
      throw ArgumentError('Exception: conflicting arguments provided');
    } else if (arguments.contains('broker')) {
      // Create a broker and await pub/sub requests
      var broker = BrokerProcess();
      await broker
          .fetchProtocol(port: port)
          .then((value) => print('Broker process started'));
    } else if (argResults.wasParsed('brokerip')) {
      brokerIP = InternetAddress(argResults['brokerip']);
      // Publish protocol sends message to broker
      if (arguments.contains('pub')) {
        await stdin.forEach((element) async {
          var message = Utf8Codec().decode(element);
          if (message == 'exit') {
            return;
          } else {
            await PublisherProcess()
                .publish(message: message, broker: brokerIP, port: port)
                .then((value) => print('Published $message to broker:$brokerIP:$port'));
          }
        });
        // Subscribe protocol links to broker and awaits messages
      } else if (arguments.contains('sub')) {
        await SubscriberProcess()
            .createSubscriberProcess(broker: brokerIP, port: port)
            .then((value) => print('Subscriber process started'));
      }
    } else {
      throw ArgumentError.value('Exception: must provide valid broker ip');
    }
  } on ArgumentError catch (e) {
    stderr.writeln(e.toString() + '\n    ' + e.message.toString());
  } catch (e) {
    stderr.writeln(e);
  }
}
