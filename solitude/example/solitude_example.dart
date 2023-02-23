import 'package:solitude/solitude.dart';
import 'package:solitude/src/fortress.dart';
import 'package:solitude/src/handlers/handler.dart';
import 'package:solitude/src/messages/command.dart';

void main() async {
  var proxy = FortressProxy();
  await proxy.start(fortressMain: _fortressMain);

  proxy.sendCommand(PrintCommand());
  proxy.sendCommand(IncrmentCommand(2));
  proxy.sendCommand(PrintCommand());
  proxy.sendCommand(DecrementByOneCommand());
  proxy.sendCommand(PrintCommand());

  await Future.delayed(Duration(seconds: 2));
  await proxy.dispose();
  print("Exiting main");
}

void _fortressMain(Fortress fortress) {
  // Setup command handlers here.
  fortress.registerHandler(IncrementHandler());
  fortress.registerHandler(DecrementHandler());
  fortress.registerHandler(PrintHandler());
}

// The main isolate and the Fortress isolate do not share the same instance of counter.
var counter = 0;

class IncrmentCommand extends Command {
  final int quantity;
  IncrmentCommand(this.quantity);
}

class IncrementHandler extends Handler<IncrmentCommand> {
  @override
  void execute(IncrmentCommand command) {
    counter += command.quantity;
  }
}

class DecrementByOneCommand extends Command {}

class DecrementHandler extends Handler<DecrementByOneCommand> {
  @override
  void execute(DecrementByOneCommand command) {
    counter -= 1;
  }
}

class PrintCommand extends Command {}

class PrintHandler extends Handler<PrintCommand> {
  @override
  void execute(PrintCommand command) {
    print("Counter = $counter");
  }
}
