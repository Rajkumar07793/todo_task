import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:todo_task/models/task.dart';

class TaskRepository {
  final String baseUrl = 'https://jsonplaceholder.typicode.com';

  // Fetch all todos from API
  Future<List<Task>> fetchTasks() async {
    final response = await http.get(Uri.parse('$baseUrl/todos'));
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Task.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load tasks');
    }
  }

  // Create a new todo via POST
  Future<Task> createTask(Task task) async {
    final response = await http.post(
      Uri.parse('$baseUrl/todos'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: json.encode(task.toJson()),
    );
    if (response.statusCode == 201) {
      return Task.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create task');
    }
  }

  // Update a todo via PATCH (e.g., mark complete)
  Future<void> updateTask(Task task) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/todos/${task.id}'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: json.encode(task.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update task');
    }
  }

  // Delete a todo via DELETE
  Future<void> deleteTask(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/todos/$id'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete task');
    }
  }

  // Placeholder for local DB interactions – to be implemented later
  // Future<List<Task>> getCachedTasks() async {}
  // Future<void> cacheTasks(List<Task>> tasks) async {}
}
