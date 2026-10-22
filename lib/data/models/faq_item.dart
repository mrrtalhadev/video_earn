import '../../core/constants/app_constants.dart';
import 'model_utils.dart';

class FaqItem {
  const FaqItem({
    required this.id,
    required this.question,
    required this.answer,
    this.sortOrder = 0,
    this.isActive = true,
  });

  final String id;
  final String question;
  final String answer;
  final int sortOrder;
  final bool isActive;

  factory FaqItem.fromDoc(Doc doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return FaqItem(
      id: doc.id,
      question: d.str(FsKeys.question),
      answer: d.str(FsKeys.answer),
      sortOrder: d.integer(FsKeys.sortOrder),
      isActive: d.boolean(FsKeys.isActive, true),
    );
  }

  Map<String, dynamic> toMap() => {
    FsKeys.question: question,
    FsKeys.answer: answer,
    FsKeys.sortOrder: sortOrder,
    FsKeys.isActive: isActive,
  };
}
