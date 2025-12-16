import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/task_bloc.dart';
import '../bloc/task_event.dart';
import '../bloc/task_state.dart';
import '../models/task.dart';
import '../widgets/task_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load tasks when screen initializes
    context.read<TaskBloc>().add(LoadTasks());
  }

  void _addTask() async {
    final title = _controller.text.trim();
    if (title.isEmpty) return;
    final newTask = Task(
        id: DateTime.now().millisecondsSinceEpoch,
        title: title,
        completed: false);
    context.read<TaskBloc>().add(AddTask(newTask));
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TaskBloc, TaskState>(
      listener: (context, state) {
        if (state is TaskError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        } else if (state is TaskLoadError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        } else if (state is TaskDeleteSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Todo List'),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () async {
                final query = await showSearch<String>(
                  context: context,
                  delegate: _TaskSearchDelegate(context.read<TaskBloc>()),
                );
                if (query != null) {
                  context.read<TaskBloc>().add(SearchTasks(query));
                }
              },
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            context.read<TaskBloc>().add(LoadTasks());
          },
          child: BlocBuilder<TaskBloc, TaskState>(
            builder: (context, state) {
              if (state is TaskLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is TaskLoaded) {
                final tasks = state.tasks;
                if (tasks.isEmpty) {
                  return const Center(child: Text('No tasks yet'));
                }
                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return TaskItem(task: task);
                  },
                );
              } else if (state is TaskLoadError) {
                final tasks = state.cachedTasks;
                if (tasks.isEmpty) {
                  return const Center(child: Text('No tasks yet'));
                }
                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return TaskItem(task: task);
                  },
                );
              } else if (state is TaskSearchResult) {
                final tasks = state.filteredTasks;
                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) => TaskItem(task: tasks[index]),
                );
              }
              // For other states, show empty container
              return const SizedBox.shrink();
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final result = await showDialog<String>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Add Task'),
                content: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(hintText: 'Task title'),
                ),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel')),
                  ElevatedButton(
                      onPressed: () => Navigator.pop(context, _controller.text),
                      child: const Text('Add')),
                ],
              ),
            );
            if (result != null && result.trim().isNotEmpty) {
              _addTask();
            }
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class _TaskSearchDelegate extends SearchDelegate<String> {
  final TaskBloc bloc;
  _TaskSearchDelegate(this.bloc);

  @override
  List<Widget>? buildActions(BuildContext context) =>
      [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
      icon: const Icon(Icons.arrow_back), onPressed: () => close(context, ''));

  @override
  Widget buildResults(BuildContext context) {
    bloc.add(SearchTasks(query));
    close(context, query);
    return const SizedBox.shrink();
  }

  @override
  Widget buildSuggestions(BuildContext context) => const SizedBox.shrink();
}
