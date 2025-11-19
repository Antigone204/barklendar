// 定义意图处理结果类型
import 'package:ai_smart_calendar/models/task_model.dart';

abstract class IntentResult {
  final String responseMessage;
  IntentResult(this.responseMessage);
}

class CreateTaskSuccess extends IntentResult {
  final TaskModel task;
  CreateTaskSuccess(String responseMessage, this.task) : super(responseMessage);
}

class GeneralResponse extends IntentResult {
  GeneralResponse(String responseMessage) : super(responseMessage);
}

class IntentError extends IntentResult {
  IntentError(String responseMessage) : super(responseMessage);
}
