import 'package:ai_smart_calendar/services/hive_service.dart';
import 'package:ai_smart_calendar/enums/ai_prompts.dart';

String generatePromptTest() {
  final String prompt = HiveService.getAiPrompt(AiPrompts.test,
      defaultValue: '你好！请用中文回复。这是一个日历应用的AI功能测试。',);
  return prompt;
}

String generatePromptSummarizeDay(String date, List<String> tasks) {
  String prompt = HiveService.getAiPrompt(AiPrompts.summarizeDay,
      defaultValue: '请总结{{date}}的日程安排：\n{{tasks}}',);
  prompt = prompt.replaceAll('{{date}}', date);
  prompt = prompt.replaceAll('{{tasks}}', tasks.join('\n'));
  return prompt;
}

String generatePromptSummarizeWeek(
    String startDate, String endDate, List<String> tasks,) {
  String prompt = HiveService.getAiPrompt(AiPrompts.summarizeWeek,
      defaultValue: '请总结{{start_date}}到{{end_date}}这一周的日程安排：\n{{tasks}}',);
  prompt = prompt.replaceAll('{{start_date}}', startDate);
  prompt = prompt.replaceAll('{{end_date}}', endDate);
  prompt = prompt.replaceAll('{{tasks}}', tasks.join('\n'));
  return prompt;
}

String generatePromptCreateEvent(
    String title, String description, String date, String time,) {
  String prompt = HiveService.getAiPrompt(AiPrompts.createEvent,
      defaultValue:
          '请帮我创建一个日程事件：\n标题：{{title}}\n描述：{{description}}\n日期：{{date}}\n时间：{{time}}',);
  prompt = prompt.replaceAll('{{title}}', title);
  prompt = prompt.replaceAll('{{description}}', description);
  prompt = prompt.replaceAll('{{date}}', date);
  prompt = prompt.replaceAll('{{time}}', time);
  return prompt;
}

String generatePromptSuggestTime(List<String> busyTimes, String duration) {
  String prompt = HiveService.getAiPrompt(AiPrompts.suggestTime,
      defaultValue: '根据以下忙碌时间：\n{{busy_times}}\n请建议一个合适的{{duration}}分钟的空闲时间段。',);
  prompt = prompt.replaceAll('{{busy_times}}', busyTimes.join('\n'));
  prompt = prompt.replaceAll('{{duration}}', duration);
  return prompt;
}

String generatePromptAnalyzeProductivity(
    List<String> completedTasks, List<String> pendingTasks,) {
  String prompt = HiveService.getAiPrompt(AiPrompts.analyzeProductivity,
      defaultValue:
          '请分析我的工作效率：\n已完成任务：{{completed_tasks}}\n待完成任务：{{pending_tasks}}',);
  prompt = prompt.replaceAll('{{completed_tasks}}', completedTasks.join('\n'));
  prompt = prompt.replaceAll('{{pending_tasks}}', pendingTasks.join('\n'));
  return prompt;
}
