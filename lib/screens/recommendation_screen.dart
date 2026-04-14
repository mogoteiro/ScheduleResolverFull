import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ai_schedule_service.dart';

class RecommendationScreen extends StatelessWidget {
  const RecommendationScreen({super.key});

  @override
  Widget build (BuildContext context) {
    // TODO implement build

    final aiService = Provider.of<AiScheduleService>(context, listen: true);
    final analysis = aiService.currentAnalysis;
    final isLoading = aiService.isLoading;
    final error = aiService.errorMessage;

    print('RecommendationScreen build: loading=$isLoading, error=$error, analysis=${analysis != null}');

    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('AI Schedule Recommendation')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Analyzing your schedule with AI...'),
            ],
          ),
        ),
      );
    }

    if (error != null && error.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('AI Schedule Recommendation')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                const Text('Error', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(error, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      );
    }

    if (analysis == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('AI Schedule Recommendation')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 48),
                SizedBox(height: 16),
                Text('No analysis available', style: TextStyle(fontSize: 18)),
                SizedBox(height: 8),
                Text('Please add tasks and try again.', textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Schedule Recommendation')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildSection(context, 'Detected Conflicts', analysis.conflicts, Colors.red.shade100, Icons.warning_amber_rounded),
              const SizedBox(height: 16),
              _buildSection(context, 'Ranked Tasks', analysis.rankedTasks, Colors.blue.shade100, Icons.list),
              const SizedBox(height: 16),
              _buildSection(context, 'Recommended Schedule', analysis.recommendedSchedule, Colors.green.shade100, Icons.schedule),
              const SizedBox(height: 16),
              _buildSection(context, 'Explanation', analysis.explanation, Colors.orange.shade100, Icons.info),
              const SizedBox(height: 16),
            ],
          ),
        ),
    );
  }

  Widget _buildSection (
      BuildContext context,
      String title,
      String content,
      Color bgColor,
      IconData icon,
      ) {
    return Card(
      color: bgColor,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size:28),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                   ),
               )
            ],
         ),
          const Divider(),
          Text(content, style: const TextStyle(fontSize: 16, height: 1.5)),
        ]
        ),
      ),
    );
  }
}