import 'package:solitude/src/messages/command.dart';

abstract class Handler<CommandType extends Command> {
  void execute(CommandType command);
}
