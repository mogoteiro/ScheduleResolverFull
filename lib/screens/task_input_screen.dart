import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/schedule_provider.dart';
import '../models/task_model.dart';
import '../services/ai_schedule_service.dart';
import 'recommendation_screen.dart';

class TaskInputScreen extends StatefulWidget {
  const TaskInputScreen({super.key});

  @override
  State<TaskInputScreen> createState() => _TaskInputScreenState();
}

class _TaskInputScreenState extends State<TaskInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();

  // State variables for task details
  String _selectedCategory = 'Work';
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay(hour: (TimeOfDay.now().hour + 1) % 24, minute: TimeOfDay.now().minute);
  int _urgency = 3;
  int _importance = 3;
  double _effort = 1.0;
  String _energyLevel = 'Medium';

  final List<String> _categories = ['Work', 'Personal', 'Health', 'Education', 'Social'];
  final List<String> _energyLevels = ['Low', 'Medium', 'High'];

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) _startTime = picked; else _endTime = picked;
      });
    }
  }

  void _saveTask() {
    if (_formKey.currentState!.validate()) {
      final newTask = TaskModel(
        id: const Uuid().v4(),
        title: _titleController.text.trim(),
        category: _selectedCategory,
        date: DateTime.now(),
        startTime: _startTime,
        endTime: _endTime,
        urgency: _urgency,
        importance: _importance,
        estimatedEffortHours: _effort,
        energyLevel: _energyLevel,
      );

      Provider.of<ScheduleProvider>(context, listen: false).addTask(newTask);
      Navigator.pop(context);
    }
  }

  Future<void> _resolveConflicts() async {
    final scheduleProvider = Provider.of<ScheduleProvider>(context, listen: false);
    final aiService = Provider.of<AiScheduleService>(context, listen: false);

    if (scheduleProvider.tasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add some tasks first!')),
      );
      return;
    }

    print('=== _resolveConflicts START ===');
    print('Tasks count: ${scheduleProvider.tasks.length}');
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      print('Calling aiService.analyzeSchedule...');
      await aiService.analyzeSchedule(scheduleProvider.tasks);
      
      print('analyzeSchedule completed');
      print('Current analysis: ${aiService.currentAnalysis != null}');
      print('Error message: ${aiService.errorMessage}');
      
      if (mounted) {
        print('Closing loading dialog...');
        Navigator.pop(context); // Close loading dialog
        
        print('Pushing RecommendationScreen...');
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const RecommendationScreen()),
        );
      }
    } catch (e) {
      print('Exception in _resolveConflicts: $e');
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AI Error: $e')),
      );
    }
    print('=== _resolveConflicts END ===');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Task'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Task Title', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Title required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField(
                value: _selectedCategory,
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _selectedCategory = v.toString()),
                decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: ListTile(title: const Text('Start'), subtitle: Text(_startTime.format(context)), onTap: () => _selectTime(context, true))),
                  Expanded(child: ListTile(title: const Text('End'), subtitle: Text(_endTime.format(context)), onTap: () => _selectTime(context, false))),
                ],
              ),
              const Divider(),
              const Text('Priority & Effort', style: TextStyle(fontWeight: FontWeight.bold)),
              Slider(value: _urgency.toDouble(), min: 1, max: 5, divisions: 4, label: 'Urgency: $_urgency', onChanged: (v) => setState(() => _urgency = v.toInt())),
              Slider(value: _importance.toDouble(), min: 1, max: 5, divisions: 4, label: 'Importance: $_importance', onChanged: (v) => setState(() => _importance = v.toInt())),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveTask,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: const Text('Add to List'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _resolveConflicts,
                style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: const Text('Resolve Conflicts with AI'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}