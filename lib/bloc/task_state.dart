import 'package:equatable/equatable.dart';

import '../models/task.dart';

abstract class TaskState extends Equatable {
  const TaskState();

  @override
  List<Object?> get props => [];
}

class TaskInitial extends TaskState {}

class TaskLoading extends TaskState {}

class TaskLoaded extends TaskState {
  final List<Task> tasks;
  const TaskLoaded(this.tasks);

  @override
  List<Object?> get props => [tasks];
}

class TaskError extends TaskState {
  final String message;
  const TaskError(this.message);

  @override
  List<Object?> get props => [message];
}

class TaskLoadError extends TaskState {
  final String message;
  final List<Task> cachedTasks;
  const TaskLoadError(this.message, this.cachedTasks);

  @override
  List<Object?> get props => [message, cachedTasks];
}

class TaskDeleteSuccess extends TaskState {
  final String message;
  const TaskDeleteSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class TaskSearchResult extends TaskState {
  final List<Task> filteredTasks;
  const TaskSearchResult(this.filteredTasks);

  @override
  List<Object?> get props => [filteredTasks];
}
