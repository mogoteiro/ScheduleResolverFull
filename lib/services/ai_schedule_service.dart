import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/task_model.dart';
import '../models/schedule_analysis.dart';

class AiScheduleService extends ChangeNotifier {
    ScheduleAnalysis? _currentAnalysis;
    bool _isLoading = false;
    String? _errorMessage;

    final String _apiKey = 'AIzaSyA0EK7HJggfVATWhfIKYID2jGD8jUAXuLA';

    ScheduleAnalysis? get currentAnalysis => _currentAnalysis;
    bool get isLoading => _isLoading;
    String? get errorMessage => _errorMessage;

    Future<void> analyzeSchedule(List<TaskModel> tasks) async {
        print('=== START analyzeSchedule ===');
        print('API Key isEmpty: ${_apiKey.isEmpty}');
        print('Tasks count: ${tasks.length}');
        
        if (_apiKey.isEmpty) {
            _errorMessage = "API key is empty";
            notifyListeners();
            return;
        }
        
        if (tasks.isEmpty) {
            _errorMessage = "No tasks provided";
            notifyListeners();
            return;
        }
        
        _isLoading = true;
        _errorMessage = null;
        notifyListeners();
        print('Set loading = true, notified listeners');

        int retries = 3;
        int delaySeconds = 2;
        
        while (retries > 0) {
            try {
                print('Creating GenerativeModel (attempt ${4 - retries})...');
                final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey:_apiKey);
                
                print('Encoding tasks to JSON...');
                final tasksJson = jsonEncode(tasks.map((t) => t.toJson()).toList());
                print('Tasks JSON: $tasksJson');
                
                final prompt = '''You are an expert student scheduling assistant. Analyze the following tasks and provide recommendations.

Tasks (JSON format): $tasksJson

Please provide your response in EXACTLY this format with these 4 markdown headers:

### Detected conflicts
[List any time conflicts found between tasks]

### Ranked Tasks
[Rank tasks by priority considering urgency, importance, and energy level]

### Recommended Schedule
[Provide a revised timeline adjusting task times to resolve conflicts]

### Explanation
[Explain why this recommendation works]

Ensure each section contains helpful content and is clearly separated by the ### headers.''';

                print('Sending request to Google AI...');
                final content = [Content.text(prompt)];
                final response = await model.generateContent(content);
                
                print('Got response from AI');
                final responseText = response.text ?? '';
                print('Response text length: ${responseText.length}');
                print('Response text: $responseText');
                
                if (responseText.isEmpty) {
                    _errorMessage = "AI returned empty response";
                    notifyListeners();
                    return;
                }
                
                print('Parsing response...');
                _currentAnalysis = _parseResponse(responseText);
                print('Analysis parsed: ${_currentAnalysis != null}');
                if (_currentAnalysis != null) {
                    print('Analysis conflicts length: ${_currentAnalysis!.conflicts.length}');
                    print('Analysis rankedTasks length: ${_currentAnalysis!.rankedTasks.length}');
                }
                print('Notifying listeners after parsing...');
                notifyListeners();
                break; // Success, exit retry loop
                
            } catch (e, stackTrace){
                retries--;
                print('ERROR (attempt ${4 - retries}): $e');
                
                if (retries > 0) {
                    print('Retrying in ${delaySeconds} seconds...');
                    await Future.delayed(Duration(seconds: delaySeconds));
                    delaySeconds *= 2; // Exponential backoff
                } else {
                    _errorMessage = "Failed to analyze schedule: $e\n\nThe AI service is currently unavailable. Please try again in a few moments.";
                    print('StackTrace: $stackTrace');
                    notifyListeners();
                }
            }
        }
        
        _isLoading = false;
        print('Set loading = false, notifying listeners');
        notifyListeners();
        print('=== END analyzeSchedule ===');
    }

    ScheduleAnalysis _parseResponse(String fullText) {
        print('=== START _parseResponse ===');
        print('Input text length: ${fullText.length}');
        
        if (fullText.isEmpty) {
            print('ERROR: Empty response text');
            return ScheduleAnalysis(
                conflicts: 'No conflicts detected.',
                rankedTasks: 'Task prioritization is loading.',
                recommendedSchedule: 'Schedule is being optimized.',
                explanation: 'Analysis in progress.',
            );
        }
        
        String conflicts = "", 
            rankedTasks = "", 
            recommendedSchedule = "",
            explanation = "";

        print('Full response:\n$fullText\n');

        // Simple approach: find each header and extract content until next header
        final lines = fullText.split('\n');
        String? currentSection;
        final sectionContent = <String, List<String>>{};
        sectionContent['conflicts'] = [];
        sectionContent['ranked'] = [];
        sectionContent['recommended'] = [];
        sectionContent['explanation'] = [];
        
        for (final line in lines) {
            final lowerLine = line.toLowerCase().trim();
            
            if (lowerLine.contains('detected') && lowerLine.contains('conflicts')) {
                currentSection = 'conflicts';
                print('Found Detected Conflicts section');
                continue;
            } 
            else if (lowerLine.contains('ranked') && lowerLine.contains('tasks')) {
                currentSection = 'ranked';
                print('Found Ranked Tasks section');
                continue;
            } 
            else if (lowerLine.contains('recommended') && lowerLine.contains('schedule')) {
                currentSection = 'recommended';
                print('Found Recommended Schedule section');
                continue;
            } 
            else if (lowerLine.contains('explanation')) {
                currentSection = 'explanation';
                print('Found Explanation section');
                continue;
            }
            
            // Skip section headers with ### markers
            if (line.contains('###')) {
                continue;
            }
            
            // Add content to current section
            if (currentSection != null && line.trim().isNotEmpty) {
                sectionContent[currentSection]!.add(line);
            }
        }
        
        conflicts = sectionContent['conflicts']!.join('\n').trim();
        rankedTasks = sectionContent['ranked']!.join('\n').trim();
        recommendedSchedule = sectionContent['recommended']!.join('\n').trim();
        explanation = sectionContent['explanation']!.join('\n').trim();

        print('Final parsed values:');
        print('  conflicts: ${conflicts.isEmpty ? "✗ EMPTY" : "✓ ${conflicts.length} chars"}');
        print('  rankedTasks: ${rankedTasks.isEmpty ? "✗ EMPTY" : "✓ ${rankedTasks.length} chars"}');
        print('  recommendedSchedule: ${recommendedSchedule.isEmpty ? "✗ EMPTY" : "✓ ${recommendedSchedule.length} chars"}');
        print('  explanation: ${explanation.isEmpty ? "✗ EMPTY" : "✓ ${explanation.length} chars"}');

        final result = ScheduleAnalysis(
            conflicts: conflicts.isEmpty ? 'No conflicts detected. Your schedule is well-organized.' : conflicts,
            explanation: explanation.isEmpty ? 'Your task schedule has been analyzed.' : explanation,
            rankedTasks: rankedTasks.isEmpty ? 'Tasks have been ranked by priority.' : rankedTasks,
            recommendedSchedule: recommendedSchedule.isEmpty ? 'A balanced schedule has been created.' : recommendedSchedule,
        );
        
        print('Analysis object created: ${result.conflicts.isNotEmpty}');
        print('=== END _parseResponse ===');
        return result;
    }
}