import 'message.dart';

abstract class Query extends Message with Identifiable {}

abstract class QueryResponse extends Message with Identifiable {}
