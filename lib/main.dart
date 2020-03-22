import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

void main() {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
    if (kReleaseMode) exit(1);
  };
  runApp(const App());
}

class App extends StatelessWidget {
  const App({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    debugPaintSizeEnabled = false;
    return MaterialApp(
      title: 'ToDo List',
      theme: ThemeData.dark(),
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (context) => _ToDoList(),
          ),
          ChangeNotifierProvider(
            create: (context) => _HideCheckedTodoList(),
          ),
        ],
        child: const _ToDoListPage(),
      ),
    );
  }
}

class _ToDoListPage extends StatelessWidget {
  const _ToDoListPage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final todolistProvider = Provider.of<_ToDoList>(context);
    return SafeArea(
      child: Scaffold(
        key: todolistProvider.scaffoldKey,
        appBar: AppBar(
          title: Text('GoriDev'),
        ),
        body: AnimatedList(
          key: todolistProvider.listKey,
          initialItemCount: todolistProvider.todoList.length,
          itemBuilder: (context, index, animation) {
            ToDoListItem todo = todolistProvider.todoList[index];
            if (todo is ToDo) {
              if (todo.isDone &&
                  Provider.of<_HideCheckedTodoList>(context).value) return null;
              return _AnimatedListItem(todo: todo, animation: animation);
            }
            if (todo is SectionHeader)
              return todolistProvider.isSectionHeaderVisible
                  ? _SectionHeader()
                  : Column();
            if (todo is EmptySheet)
              return todolistProvider.isEmptySheetVisible
                  ? _EmptySheet()
                  : Column();
            return null;
          },
        ),
        floatingActionButton: AddTodoButton(
          onFormSubmit: todolistProvider.add,
        ),
      ),
    );
  }
}

class _AnimatedListItem extends StatelessWidget {
  final ToDo todo;
  final Animation animation;
  const _AnimatedListItem({Key key, this.todo, this.animation})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 16.0),
        child: Icon(Icons.delete_forever),
      ),
      key: Key(todo.hashCode.toString()),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        Provider.of<_ToDoList>(context).remove(
          todo: todo,
          duration: Duration(milliseconds: 0),
          buildAnimatedListItem: (todo, animation) => _AnimatedListItem(
            todo: todo,
            animation: animation,
          ),
        );

        final snackBar = SnackBar(
          content: Text('タスクを削除しました'),
          action: SnackBarAction(
            label: '元に戻す',
            onPressed: Provider.of<_ToDoList>(context).undoRemove,
          ),
        );
        Provider.of<_ToDoList>(context)
            .scaffoldKey
            .currentState
            .showSnackBar(snackBar);
      },
      child: ScaleTransition(
        scale: animation.drive(
          CurveTween(
            curve: const Interval(0, 1, curve: Curves.fastOutSlowIn),
          ),
        ),
        child: _ToDoListItemView(
          todo: todo,
        ),
      ),
    );
  }
}

class _ToDoListItemView extends StatelessWidget {
  final ToDo todo;
  const _ToDoListItemView({Key key, @required this.todo}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: IconButton(
        icon: Icon(todo.isDone ? Icons.check : Icons.radio_button_unchecked),
        onPressed: () {
          Provider.of<_ToDoList>(context).toggle(
            todo: todo,
            buildAnimatedListItem: (todo, animation) => _AnimatedListItem(
              todo: todo,
              animation: animation,
            ),
          );
        },
      ),
      title: Text(todo.text),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text('完了済み', style: TextStyle(fontSize: 12.0)),
      trailing: IconButton(
        icon: Icon(
          Provider.of<_HideCheckedTodoList>(context).value
              ? Icons.expand_more
              : Icons.expand_less,
          size: 20.0,
        ),
        onPressed: Provider.of<_HideCheckedTodoList>(context).toggle,
      ),
    );
  }
}

class _EmptySheet extends StatelessWidget {
  const _EmptySheet({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          padding: EdgeInsets.fromLTRB(32, 64, 32, 0),
          child: Image.asset(
            'assets/images/empty_image.png',
          ),
        ),
        Text(
          'やるべきことはありません',
          style: Theme.of(context).primaryTextTheme.body1,
        ),
        Text(
          'タスクを追加してみましょう',
          style: Theme.of(context).primaryTextTheme.caption,
        ),
      ],
    );
  }
}

class _ToDoList extends ValueNotifier<List<ToDo>> {
  _ToDoList() : super([]);

  final GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();
  final GlobalKey<AnimatedListState> listKey = GlobalKey<AnimatedListState>();

  List<ToDo> get _checkedToDoList =>
      value.where((todo) => todo.isDone).toList();
  List<ToDo> get _uncheckedToDoList =>
      value.where((todo) => !todo.isDone).toList();

  List<ToDoListItem> get todoList => []
    ..addAll(_uncheckedToDoList)
    ..add(EmptySheet())
    ..add(SectionHeader())
    ..addAll(_checkedToDoList);

  bool get isEmptySheetVisible => _uncheckedToDoList.isEmpty;
  bool get isSectionHeaderVisible => _checkedToDoList.isNotEmpty;

  AnimatedListState get _animatedList => listKey.currentState;

  ToDo _lastRemovedToDo;
  int _lastRemovedToDoIndex;

  void add(String todoText) {
    var todo = ToDo(text: todoText);
    _insertToDo(todo: todo, index: 0);
  }

  void remove({
    ToDo todo,
    Widget Function(ToDo todo, Animation animation) buildAnimatedListItem,
    Duration duration,
  }) {
    var animatedIndex = todoList.indexOf(todo);
    _removeToDo(
        todo: todo,
        animatedIndex: animatedIndex,
        duration: duration,
        buildAnimatedListItem: buildAnimatedListItem);
  }

  void undoRemove() {
    _insertToDo(todo: _lastRemovedToDo, index: _lastRemovedToDoIndex);
  }

  void toggle(
      {ToDo todo,
      Widget Function(ToDo todo, Animation animation)
          buildAnimatedListItem}) async {
    // アニメーションのduration
    const removeDuration = Duration(milliseconds: 275);
    const insertDuration = Duration(milliseconds: 225);
    const delay = Duration(milliseconds: 200);

    // リストから削除
    var animatedIndex = todoList.indexOf(todo);
    _removeToDo(
        todo: todo,
        animatedIndex: animatedIndex,
        duration: removeDuration,
        buildAnimatedListItem: buildAnimatedListItem);

    // 削除のアニメーションが終わるまで待つ
    await new Future.delayed(delay);

    // リストの先頭に追加
    _insertToDo(
        todo: todo,
        index: todo.isDone ? 0 : _uncheckedToDoList.length,
        duration: insertDuration);

    // チェック状態を変更
    todo.toggle();
  }

  void _insertToDo(
      {ToDo todo,
      int index,
      Duration duration = const Duration(milliseconds: 200)}) {
    value.insert(index, todo);
    _animatedList.insertItem(
      index,
      duration: duration,
    );
  }

  void _removeToDo(
      {ToDo todo,
      int animatedIndex,
      Duration duration = const Duration(milliseconds: 200),
      Widget Function(ToDo todo, Animation animation) buildAnimatedListItem}) {
    _lastRemovedToDoIndex = value.indexOf(todo);
    _lastRemovedToDo = todo;
    value.remove(todo);
    _animatedList.removeItem(
      animatedIndex,
      (context, animation) => buildAnimatedListItem(todo, animation),
      duration: duration,
    );
  }
}

class _HideCheckedTodoList extends ValueNotifier<bool> {
  _HideCheckedTodoList() : super(false);

  void toggle() => value = !value;
}

class AddTodoButton extends StatefulWidget {
  final void Function(String todo) onFormSubmit;
  AddTodoButton({Key key, this.onFormSubmit}) : super(key: key);

  @override
  _AddTodoButtonState createState() => _AddTodoButtonState();
}

class _AddTodoButtonState extends State<AddTodoButton> {
  final inputTodoTextController = TextEditingController();

  void _handleSaveButtonTap() {
    // フォームが空ならボトムシートを閉じる
    if (inputTodoTextController.text.isEmpty) {
      Navigator.pop(context);
      return;
    }
    widget.onFormSubmit(inputTodoTextController.text);
    // テキス���フィ���ル���をクリアす���
    inputTodoTextController.clear();
    // ボ���������ム����ートを閉じる
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: null,
      icon: Icon(
        Icons.edit,
        // size: 32,
      ),
      label: Text(
        'タスクを追加',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      onPressed: () async {
        await showModalBottomSheet<Widget>(
          context: context,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          builder: (BuildContext context) {
            return SafeArea(
              child: Container(
                margin: (MediaQuery.of(context).viewInsets.bottom > 0)
                    ? EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom)
                    : EdgeInsets.all(0.0),
                padding: EdgeInsets.fromLTRB(16.0, 16.0, 8.0, 0.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: 4.0),
                    ),
                    TextFormField(
                      autofocus: true,
                      controller: inputTodoTextController,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (text) {
                        _handleSaveButtonTap();
                      },
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 12.0),
                        border: InputBorder.none,
                        labelText: '新しいタスク',
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 8.0),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.menu),
                              onPressed: () {},
                            ),
                            IconButton(
                              icon: Icon(Icons.calendar_today),
                              onPressed: () {},
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            FlatButton(
                              child: Text(
                                '保存',
                                style: TextStyle(
                                  fontSize: 16.0,
                                ),
                              ),
                              onPressed: _handleSaveButtonTap,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    inputTodoTextController.dispose();
    super.dispose();
  }
}

abstract class ToDoListItem {}

class ToDo extends ToDoListItem {
  String text;
  bool isDone;
  ToDo({@required this.text, this.isDone = false});

  void toggle() => isDone = !isDone;
}

class SectionHeader extends ToDoListItem {}

class EmptySheet extends ToDoListItem {}
