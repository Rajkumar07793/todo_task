import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/local_db.dart';
import '../models/task.dart';
import '../repositories/task_repository.dart';
import 'task_event.dart';
import 'task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final TaskRepository repository;
  final LocalDatabase localDb;

  TaskBloc({required this.repository, required this.localDb})
      : super(TaskInitial()) {
    on<LoadTasks>(_onLoadTasks);
    on<AddTask>(_onAddTask);
    on<UpdateTask>(_onUpdateTask);
    on<DeleteTask>(_onDeleteTask);
    on<SearchTasks>(_onSearchTasks);
  }

  Future<void> _onLoadTasks(LoadTasks event, Emitter<TaskState> emit) async {
    emit(TaskLoading());
    try {
      // Load cached tasks first
      final cached = await localDb.getAllTasks();
      emit(TaskLoaded(cached));
      // Then fetch from API and sync
      final remote = await repository.fetchTasks();
      // Update local cache
      for (var task in remote) {
        await localDb.insertTask(task);
      }
      emit(TaskLoaded(remote));
    } catch (e) {
      emit(TaskError(e.toString()));
    }
  }

  Future<void> _onAddTask(AddTask event, Emitter<TaskState> emit) async {
    if (state is TaskLoaded) {
      final current = (state as TaskLoaded).tasks;
      final optimisticList = List<Task>.from(current)..add(event.task);
      emit(TaskLoaded(optimisticList));
      try {
        final created = await repository.createTask(event.task);
        await localDb.insertTask(created);
        // Replace optimistic task with server version (id may differ)
        final updatedList = optimisticList
            .map((t) => t.id == event.task.id ? created : t)
            .toList();
        emit(TaskLoaded(updatedList));
      } catch (e) {
        // Revert optimistic addition
        final reverted = List<Task>.from(current);
        emit(TaskLoaded(reverted));
        emit(TaskError('Failed to add task: ${e.toString()}'));
      }
    }
  }

  Future<void> _onUpdateTask(UpdateTask event, Emitter<TaskState> emit) async {
    if (state is TaskLoaded) {
      final current = (state as TaskLoaded).tasks;
      final optimisticList =
          current.map((t) => t.id == event.task.id ? event.task : t).toList();
      emit(TaskLoaded(optimisticList));
      try {
        await repository.updateTask(event.task);
        await localDb.updateTask(event.task);
        // keep optimistic list as final
        emit(TaskLoaded(optimisticList));
      } catch (e) {
        // revert to previous state
        emit(TaskLoaded(current));
        emit(TaskError('Failed to update task: ${e.toString()}'));
      }
    }
  }

  Future<void> _onDeleteTask(DeleteTask event, Emitter<TaskState> emit) async {
    if (state is TaskLoaded) {
      final current = (state as TaskLoaded).tasks;
      final optimisticList =
          current.where((t) => t.id != event.taskId).toList();
      emit(TaskLoaded(optimisticList));
      try {
        await repository.deleteTask(event.taskId);
        await localDb.deleteTask(event.taskId);
        emit(TaskLoaded(optimisticList));
      } catch (e) {
        // revert deletion
        emit(TaskLoaded(current));
        emit(TaskError('Failed to delete task: ${e.toString()}'));
      }
    }
  }

  void _onSearchTasks(SearchTasks event, Emitter<TaskState> emit) {
    if (state is TaskLoaded) {
      final all = (state as TaskLoaded).tasks;
      final filtered = all
          .where(
              (t) => t.title.toLowerCase().contains(event.query.toLowerCase()))
          .toList();
      emit(TaskSearchResult(filtered));
    }
  }
}
