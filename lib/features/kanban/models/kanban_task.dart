import 'package:appflowy_board/appflowy_board.dart';

class KanbanTask extends AppFlowyGroupItem {
  final String title;

  KanbanTask(this.title);

  @override
  String get id => title;
}
