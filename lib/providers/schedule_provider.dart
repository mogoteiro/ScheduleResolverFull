import 'package:flutter/material.dart';
import '../models/task_model.dart';
import 'package:uuid/uuid.dart';

class ScheduleProvider extends ChangeNotifier{
    final List<TaskModel> _tasks =[];
    final Uuid _uuid = const Uuid();

    List<TaskModel> get tasks => _tasks;

    void addTask(TaskModel newTask) {
        _tasks.add(newTask);
        notifyListeners();
    }
    void removeTask(String id){
        _tasks.removeWhere((task) => task.id == id);
        notifyListeners();
    }
}