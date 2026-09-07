import 'package:seban_board/core/constants/assets.dart';
import '../models/kanban.dart';

class BirthdayService {
  final int _targetMonth = 9;
  final int _targetDay = 9;

  bool get isBirthday {
    final now = DateTime.now();
    return now.month == _targetMonth && now.day == _targetDay;
  }

  /// Scans the categories for the "happy birthday" sequence and injects the surprise.
  /// Returns [true] if the event was successfully activated.
  bool applyBirthdayEvent(List<KanbanCategory> categories) {
    bool bdayActivated = false;

    for (int i = 0; i < categories.length - 1; i++) {
      final currentCategory = categories[i];
      final nextCategory = categories[i + 1];
      final currentName = currentCategory.name.trim().toLowerCase();
      final nextName = nextCategory.name.trim().toLowerCase();

      if (currentName == 'happy' && nextName == 'birthday') {
        // Update Current Category
        currentCategory.items.add(KanbanTask("Sebastian"));
        categories[i] = KanbanCategory(
          id: currentCategory.id,
          name: "${currentName[0].toUpperCase()}${currentName.substring(1)}",
          items: currentCategory.items,
        );

        // Update Next Category
        nextCategory.items.add(KanbanTask("James"));
        categories[i + 1] = KanbanCategory(
          id: nextCategory.id,
          name: "${nextName[0].toUpperCase()}${nextName.substring(1)}",
          items: nextCategory.items,
        );

        // Skip if "To You" is already injected
        if (i + 2 < categories.length && categories[i + 2].name == 'To You') {
          continue;
        }

        // Inject the Surprise Cake
        final surpriseCategory = KanbanCategory(
          id: 'seb_bday_${DateTime.now().millisecondsSinceEpoch}',
          name: 'To You',
          items: [KanbanTask('Sampao', imagePath: Assets.images.bdayCake)],
        );

        categories.insert(i + 2, surpriseCategory);
        bdayActivated = true;
      }
    }

    return bdayActivated;
  }
}
