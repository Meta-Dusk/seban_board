import 'package:seban_board/features/kanban/models/kanban_task.dart';

class Assets {
  const Assets._();

  static const tasks = _PresetTasks();
  static const categories = _PresetCategories();
  static const images = _Images();
}

class _Images {
  const _Images();

  final String bdayCake = 'assets/images/bday_cake.png';
}

class _PresetTasks {
  const _PresetTasks();

  final aespa = _aespa;
  final leSerrafim = _leSerrafim;
  final redVelvet = _redVelvet;
  final newJeans = _newJeans;
  final illit = _illit;
  final babymonster = _babymonster;
  final katseye = _katseye;
  final twice = _twice;
  final availableList = _availableList;

  static const List<KanbanTask> _aespa = [
    KanbanTask('Karina', imagePath: 'assets/images/aespa/karina.png'),
    KanbanTask('Giselle', imagePath: 'assets/images/aespa/giselle.jpg'),
    KanbanTask('Winter', imagePath: 'assets/images/aespa/winter.jpg'),
    KanbanTask('Ningning', imagePath: 'assets/images/aespa/ningning.jpg'),
  ];

  static const List<KanbanTask> _leSerrafim = [
    KanbanTask(
      'Kim Chae-won',
      imagePath: 'assets/images/le_serrafim/chaewon.jpg',
    ),
    KanbanTask('Kazuha', imagePath: 'assets/images/le_serrafim/kazuha.png'),
    KanbanTask(
      'Sakura Miyawaki',
      imagePath: 'assets/images/le_serrafim/sakura.png',
    ),
    KanbanTask(
      'Huh Yun-jin',
      imagePath: 'assets/images/le_serrafim/yunjin.jpg',
    ),
    KanbanTask(
      'Hong Eun-chae',
      imagePath: 'assets/images/le_serrafim/eunchae.png',
    ),
    KanbanTask('Jun Ga-ram', imagePath: 'assets/images/le_serrafim/kim.png'),
  ];

  static const List<KanbanTask> _redVelvet = [
    KanbanTask('Irene', imagePath: 'assets/images/red_velvet/irene.jpg'),
    KanbanTask('Yeri', imagePath: 'assets/images/red_velvet/yeri.jpg'),
    KanbanTask('Seulgi', imagePath: 'assets/images/red_velvet/seulgi.png'),
    KanbanTask('Wendy', imagePath: 'assets/images/red_velvet/wendy.png'),
    KanbanTask('Joy', imagePath: 'assets/images/red_velvet/joy.jpg'),
  ];

  static const List<KanbanTask> _newJeans = [
    KanbanTask('Danielle', imagePath: 'assets/images/new_jeans/danielle.png'),
    KanbanTask('Minji', imagePath: 'assets/images/new_jeans/minji.jpg'),
    KanbanTask('Hanni', imagePath: 'assets/images/new_jeans/hanni.png'),
    KanbanTask('Haerin', imagePath: 'assets/images/new_jeans/haerin.png'),
    KanbanTask('Hyein', imagePath: 'assets/images/new_jeans/hyein.png'),
  ];

  static const List<KanbanTask> _illit = [
    KanbanTask('Wonhee', imagePath: 'assets/images/illit/wonhee.jpeg'),
    KanbanTask('Moka', imagePath: 'assets/images/illit/moka.png'),
    KanbanTask('Minju', imagePath: 'assets/images/illit/minju.jpg'),
    KanbanTask('Iroha', imagePath: 'assets/images/illit/iroha.png'),
    KanbanTask('Yunah', imagePath: 'assets/images/illit/yunah.png'),
  ];

  static const List<KanbanTask> _babymonster = [
    KanbanTask('Ahyeon', imagePath: 'assets/images/babymonster/ahyeon.png'),
    KanbanTask('Rami', imagePath: 'assets/images/babymonster/rami.png'),
    KanbanTask('Asa', imagePath: 'assets/images/babymonster/asa.png'),
    KanbanTask('Chiquita', imagePath: 'assets/images/babymonster/chiquita.png'),
    KanbanTask('Ruka', imagePath: 'assets/images/babymonster/ruka.jpg'),
    KanbanTask('Rora', imagePath: 'assets/images/babymonster/rora.png'),
    KanbanTask('Pharita', imagePath: 'assets/images/babymonster/pharita.png'),
  ];

  static const List<KanbanTask> _katseye = [
    KanbanTask('Manon Bannerman', imagePath: 'assets/images/katseye/manon.png'),
    KanbanTask(
      'Daniela Avanzini',
      imagePath: 'assets/images/katseye/daniela.png',
    ),
    KanbanTask(
      'Sophia Laforteza',
      imagePath: 'assets/images/katseye/sophia.png',
    ),
    KanbanTask('Yoonchae', imagePath: 'assets/images/katseye/yoonchae.png'),
    KanbanTask('Lara Raj', imagePath: 'assets/images/katseye/lara.jpg'),
    KanbanTask('Megan Skiendiel', imagePath: 'assets/images/katseye/megan.png'),
  ];

  static const List<KanbanTask> _twice = [
    KanbanTask('Minatozaki Sana', imagePath: 'assets/images/twice/sana.jpg'),
    KanbanTask('Jihyo', imagePath: 'assets/images/twice/jihyo.png'),
    KanbanTask('Momo', imagePath: 'assets/images/twice/momo.jpg'),
    KanbanTask('Tzuyu', imagePath: 'assets/images/twice/tzuyu.png'),
    KanbanTask('Jeongyeon', imagePath: 'assets/images/twice/jeongyeon.png'),
    KanbanTask('Nayeon', imagePath: 'assets/images/twice/nayeon.jpg'),
    KanbanTask('Chaeyoung', imagePath: 'assets/images/twice/chaeyoung.jpg'),
    KanbanTask('Mina', imagePath: 'assets/images/twice/mina.png'),
    KanbanTask('Dahyun', imagePath: 'assets/images/twice/dahyun.jpg'),
  ];

  static const List<KanbanTask> _availableList = [
    KanbanTask(
      'Looks like you found a secret feature! '
      'There are a bunch more available preset lists. Try making another '
      'category with one of the following names below:',
    ),
    KanbanTask('aespa'),
    KanbanTask('le serrafim'),
    KanbanTask('red velvet'),
    KanbanTask('illit'),
    KanbanTask('babymonster'),
    KanbanTask('katseye'),
    KanbanTask('twice'),
  ];
}

class _PresetCategories {
  const _PresetCategories();

  final tutorials = _tutorials;

  static const List<KanbanCategory> _tutorials = [
    KanbanCategory(
      id: 'welcome',
      name: 'Welcome',
      items: [
        KanbanTask(
          'Hi, welcome to SebanBoard! This is just a simple Kanban Board app '
          'made initially for a friend of mine.',
        ),
      ],
    ),
    KanbanCategory(
      id: 'tutorial',
      name: 'Tutorial',
      items: [
        KanbanTask(
          "Click the \"Add Task\" button below to add a task... "
          "It's self-explanatory :)",
        ),
        KanbanTask(
          "You can drag tasks around, and if you swipe on them,"
          "you can either edit or delete them.",
        ),
        KanbanTask('You can simply edit all text by double-clicking them.'),
        KanbanTask(
          "Try adding a new category, by clicking the "
          "'+' button at the top-right!",
        ),
        KanbanTask("You can also drag around the categories!"),
        KanbanTask(
          "And you can even resize the categories' width by clicking and "
          "dragging the vertical bar ('|') in the header of the category.",
        ),
      ],
    ),
  ];
}
