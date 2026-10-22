import '../../core/constants/app_constants.dart';
import 'model_utils.dart';

/// `users/{uid}/completions/{taskId}` — create-only.
class TaskCompletion {
  const TaskCompletion({required this.taskId, required this.reward, this.completedAt});

  final String taskId;
  final int reward;
  final DateTime? completedAt;

  factory TaskCompletion.fromDoc(Doc doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return TaskCompletion(taskId: doc.id, reward: d.integer(FsKeys.reward), completedAt: d.date(FsKeys.completedAt));
  }
}
