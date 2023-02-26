An experimental library for offloading app state and computation from the main isolate.

## Features

Solitude makes it easy to create a long lived isolate that can receive messages from the main isolate and optionally respond to them.

## Getting started

Add the Solitude dependency to the `pubspec.yaml` file.  Create a `FortressProxy` and start it up, passing a `Fortress` initialization function to the `start` method.  The initialization function will run in the spawned isolate and should register `Message` `Handler`s.  A handler processes specific message types sent to the isolate.  To interact with the isolate send messages or queries using `FortressProxy.sendMessage` and `FortressProxy.sendQuery`.  A query returns a single response asynchronously.

## Usage

TODO: Include short and useful examples for package users. Add longer examples
to `/example` folder. 

```dart
void main() async {
  // Create a proxy and start it up.
  final proxy = FortressProxy();
  await proxy.start(fortressMain: _fortressMain);

  // Send a command and query
  proxy.sendMessage(IncrmentCommand(2));
  final response = await proxy.sendQuery(QueryCounter()) as QueryCounterResponse;
  print("Counter: ${response.counter}");

  // It is important to shutdown the fortress or else the program won't terminate properly.
  await proxy.dispose();
}

// Setup command handlers here.
void _fortressMain(Fortress fortress) {
  fortress.registerHandler(IncrementHandler());
  fortress.registerHandler(QueryCounterHandler());
}

var counter = 0;

// Messages are passed between isolates.
class IncrmentCommand extends Message {
  final int quantity;
  IncrmentCommand(this.quantity);
}

// Handlers run in the Fortress isolate
class IncrementHandler extends Handler<IncrmentCommand> {
  @override
  void handle(IncrmentCommand command) {
    counter += command.quantity;
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

```

