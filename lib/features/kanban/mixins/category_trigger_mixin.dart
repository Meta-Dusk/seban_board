import 'package:seban_board/core/constants/assets.dart';
import '../models/kanban.dart';

mixin CategoryTriggerMixin {
  /// Checks the category name against known easter eggs and
  /// returns preset tasks if found.
  List<KanbanTask> getPresetTasksForCategory(String categoryName) {
    final normalizedName = categoryName.trim().toLowerCase();

    final presetMap = {
      'aespa': Assets.tasks.aespa,
      'le serrafim': Assets.tasks.leSerrafim,
      'red velvet': Assets.tasks.redVelvet,
      'illit': Assets.tasks.illit,
      'babymonster': Assets.tasks.babymonster,
      'katseye': Assets.tasks.katseye,
      'twice': Assets.tasks.twice,
      '_list': Assets.tasks.availableList,
    };

    final presetTasks = presetMap[normalizedName];
    if (presetTasks != null) {
      // Return a mutable copy of the const list to avoid UnsupportedError
      return presetTasks.toList();
    }

    return []; // Return empty list if no trigger matches
  }
}
