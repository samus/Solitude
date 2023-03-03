An experimental library for offloading app state and computation from the main isolate.

## Features

As more and more devices utilize higher and higher refresh rate displays, the amount of time a Flutter app can spend processing user actions and managing state decreases.  When an app takes too long to perform these actions, frames start dropping. Solitude makes it easy to create a long lived isolate that can receive messages from the main isolate and optionally respond to them thus freeing up the main isolate to concentrate on rendering widgets.  

`Isolate.run()` and Flutter's `compute()` functions use short lived isolates that are spun up and spun down after a short amount of work is done.  There is a small amount of overhead in the startup process.  Additionally, possibly large amounts of data must be transferred in and out of the isolate.  Solitude operates under the principle of keeping calculations close to the data and only transferring out what is needed for display.

## Getting started

Add the Solitude dependency to the `pubspec.yaml` file.  Create a `FortressProxy` and start it up, passing a `Fortress` initialization function to the `start` method.  The initialization function will run in the spawned isolate and should register `Message` `Handler`s.  A handler processes specific message types sent to the isolate.  To interact with the isolate send messages or queries using `FortressProxy.sendMessage` and `FortressProxy.sendQuery`.  A query returns a single response asynchronously.

## Usage

Basic steps for use is to create a proxy and start it passing in a function that receives a `Fortress` instance.  This function is referred to as the `fortressMain` function.  There are no requirements for the actual name of the function.  This method will execute inside of the isolate created by the proxy.  Any startup code to setup the isolate can be run here.  Additionally handlers to respond to messages sent from the proxy should be registered in this method.  Once the proxy start future has been completed, it is ready to send messages to the `Fortress` and receive responses.  The general pattern is to send a command and query messages to the fortress via the proxy.  Command messages tell the Fortress to do something while Query messages request data.  At the end of the program lifecycle, the dispose method should be called on the proxy to tell the Fortress to shutdown.  Failure to do so may result in the program not shutting down and hanging.

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

var counter = 0;  // There are two isolateed instances of counter, one in the main isolate and one in the Fortress isolate.

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

### Query Streams ###

In addition to single queries, a handler may also mix in `StreamingHandler` to stream results to the proxy as they are received.  The underlying mechanism is a proxy stream in the main isolate receives values from another stream in the Fortress.  Simply define a StreamingHandler and register it in the fortressMain function.  Calling the `observeQuery` method on the proxy will return a standard Dart stream that can be listened to.  All control functions executed on the StreamSubscription are forwarded to the Fortress Stream.  Calling `cancel` on the subscription will tear down the stream in the Fortress.

```dart
class QueryCounterHandler extends Handler<QueryCounter> with StreamingHandler {
  // Broadcast is used here to share a single stream with multiple listeners.  The only
  // requirement is for the open function to return a stream that can be listened to.
  final StreamController<QueryCounterResponse> _controller = StreamController.broadcast();
  
  @override
  Stream<QueryResponse> open(QueryCounter message) {
    return _controller.stream;
  }
}

void _fortressMain(Fortress fortress) {
  // Not shown here is how to share the state between handlers.
  fortress.registerHandler(IncrementHandler());
  fortress.registerHandler(QueryCounterHandler());
}

final subscription = proxy.observeQuery<QueryCounterResponse>(QueryCounter()).listen((event) {
  print("Counter stream: ${event.counter}");
});

// Send a message to the fortress to tell it to alter the counter state and allow QueryCounterHandler
// to pick up on the state change and send it to the proxy. 
proxy.sendMessage(IncrmentCommand(1));

// Cancel the subscription when finished with it
await subscription.cancel();

```