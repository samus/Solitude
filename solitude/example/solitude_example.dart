import 'package:solitude/solitude.dart';

void main() async {
  final proxy = FortressProxy();
  await proxy.start(fortressMain: _fortressMain);

  proxy.sendMessage(IncrmentCommand(2));
  await printCounter(proxy);

  proxy.sendMessage(DecrementByOneCommand());
  await printCounter(proxy);

  await proxy.dispose();
  print("Exiting main");
}

Future<void> printCounter(FortressProxy proxy) async {
  final response =
      await proxy.sendQuery(QueryCounter()) as QueryCounterResponse;
  print("Counter: ${response.counter}");
}

void _fortressMain(Fortress fortress) {
  // Setup command handlers here.
  fortress.registerHandler(IncrementHandler());
  fortress.registerHandler(DecrementHandler());
  fortress.registerHandler(QueryCounterHandler());
}

// The main isolate and the Fortress isolate do not share the same instance of counter.
var counter = 0;

class IncrmentCommand extends Message {
  final int quantity;
  IncrmentCommand(this.quantity);
}

class IncrementHandler extends Handler<IncrmentCommand> {
  @override
  void handle(IncrmentCommand command) {
    counter += command.quantity;
  }
}

class DecrementByOneCommand extends Message {}

class DecrementHandler extends Handler<DecrementByOneCommand> {
  @override
  void handle(DecrementByOneCommand command) {
    counter -= 1;
  }
}

class QueryCounter extends Query {}

class QueryCounterResponse extends QueryResponse {
  final int counter;
  QueryCounterResponse(this.counter);
}

class QueryCounterHandler extends Handler<QueryCounter> with RespondingHandler {
  @override
  void handleWithResponse(
      QueryCounter message, void Function(QueryResponse response) respond) {
    respond(QueryCounterResponse(counter));
  }
}
