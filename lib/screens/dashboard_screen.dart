import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/schedule_provider.dart';
import '../models/task_model.dart';
import 'task_input_screen.dart';
import 'recommendation_screen.dart';
import 'package:schedule_resolver_app/services/ai_schedule_service.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final schedulerProvider = Provider.of<ScheduleProvider>(context);
    final aiService = Provider.of<AiScheduleService>(context);

    // Fixed naming: changed sortingTasks to sortedTasks to match usages below
    final sortedTasks = List<TaskModel>.from(schedulerProvider.tasks);
    sortedTasks.sort((a, b) => a.startTime.hour.compareTo(b.startTime.hour));

    return Scaffold(
      appBar: AppBar(
          title: const Text('Schedule Resolver'), centerTitle: true),
      body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (aiService.currentAnalysis != null)
                Card(
                  color: Colors.green.shade100,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text('Recommendation Ready!!!',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        ElevatedButton(
                            onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                    const RecommendationScreen())),
                            child: const Text('View Recommendation'))
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Expanded(
                child: sortedTasks.isEmpty
                    ? const Center(child: Text('No task!!!'))
                    : ListView.builder(
                  itemCount: sortedTasks.length,
                  itemBuilder: (context, index) {
                    final task = sortedTasks[index];
                    return Card(
                      child: ListTile(
                        title: Text(task.title),
                        // Fixed string interpolation: removed backslashes
                        subtitle: Text(
                            "${task.category} | ${task.startTime.hour.toString().padLeft(2, '0')}:${task.startTime.minute.toString().padLeft(2, '0')}"),
                        trailing: IconButton(
                            icon: const Icon(Icons.delete,
                                color: Colors.red),
                            onPressed: () =>
                                schedulerProvider.removeTask(task.id)),
                      ),
                    );
                  },
                ),
              ),
              if (sortedTasks.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: ElevatedButton(
                    onPressed: aiService.isLoading
                        ? null
                        : () => aiService.analyzeSchedule(schedulerProvider.tasks),
                    child: aiService.isLoading
                        ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Resolve Conflicts with AI'),
                  ),
                ),
            ],
          )),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const TaskInputScreen())),
        child: const Icon(Icons.add),
      ),
    );
  }
}