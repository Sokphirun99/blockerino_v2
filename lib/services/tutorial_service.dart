import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage tutorial state and progress.
/// Handles persistence of tutorial completion and step progress.
class TutorialService {
  // SharedPreferences keys
  static const String _completedKey = 'tutorial_completed';
  static const String _currentStepKey = 'tutorial_current_step';
  static const String _completedStepsKey = 'tutorial_completed_steps';

  // Total number of tutorial steps (0-4)
  static const int totalSteps = 5;

  // Singleton instance
  static final TutorialService _instance = TutorialService._internal();
  factory TutorialService() => _instance;
  TutorialService._internal();

  // Cached values for quick access
  bool? _isCompleted;
  int? _currentStep;
  List<int>? _completedSteps;

  /// Check if tutorial has been completed
  Future<bool> isCompleted() async {
    if (_isCompleted != null) return _isCompleted!;
    
    final prefs = await SharedPreferences.getInstance();
    _isCompleted = prefs.getBool(_completedKey) ?? false;
    return _isCompleted!;
  }

  /// Mark tutorial as completed
  Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_completedKey, true);
    _isCompleted = true;
    
    // Also mark all steps as completed
    _completedSteps = List.generate(totalSteps, (i) => i);
    await _saveCompletedSteps(prefs);
  }

  /// Reset tutorial (for testing or settings)
  Future<void> resetTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_completedKey, false);
    await prefs.setInt(_currentStepKey, 0);
    await prefs.setStringList(_completedStepsKey, []);
    
    _isCompleted = false;
    _currentStep = 0;
    _completedSteps = [];
  }

  /// Get current tutorial step (for resuming)
  Future<int> getCurrentStep() async {
    if (_currentStep != null) return _currentStep!;
    
    final prefs = await SharedPreferences.getInstance();
    _currentStep = prefs.getInt(_currentStepKey) ?? 0;
    return _currentStep!;
  }

  /// Save current step progress
  Future<void> saveCurrentStep(int step) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_currentStepKey, step);
    _currentStep = step;
  }

  /// Mark a specific step as completed
  Future<void> markStepCompleted(int step) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load existing completed steps
    final steps = await getCompletedSteps();
    
    // Add step if not already completed
    if (!steps.contains(step)) {
      steps.add(step);
      steps.sort();
      _completedSteps = steps;
      await _saveCompletedSteps(prefs);
    }
    
    // Update current step to next one
    if (step + 1 < totalSteps) {
      await saveCurrentStep(step + 1);
    }
  }

  /// Get list of completed steps
  Future<List<int>> getCompletedSteps() async {
    if (_completedSteps != null) return List.from(_completedSteps!);
    
    final prefs = await SharedPreferences.getInstance();
    final stepStrings = prefs.getStringList(_completedStepsKey) ?? [];
    _completedSteps = stepStrings.map((s) => int.tryParse(s) ?? 0).toList();
    return List.from(_completedSteps!);
  }

  /// Check if a specific step has been completed
  Future<bool> isStepCompleted(int step) async {
    final steps = await getCompletedSteps();
    return steps.contains(step);
  }

  /// Get tutorial progress as percentage (0.0 - 1.0)
  Future<double> getProgress() async {
    final steps = await getCompletedSteps();
    return steps.length / totalSteps;
  }

  /// Check if user should see tutorial (not completed and not skipped)
  Future<bool> shouldShowTutorial() async {
    return !(await isCompleted());
  }

  /// Save completed steps to SharedPreferences
  Future<void> _saveCompletedSteps(SharedPreferences prefs) async {
    final stepStrings = _completedSteps!.map((s) => s.toString()).toList();
    await prefs.setStringList(_completedStepsKey, stepStrings);
  }

  /// Clear cached values (useful for testing)
  void clearCache() {
    _isCompleted = null;
    _currentStep = null;
    _completedSteps = null;
  }

  /// Get tutorial state summary for debugging
  Future<Map<String, dynamic>> getDebugInfo() async {
    return {
      'isCompleted': await isCompleted(),
      'currentStep': await getCurrentStep(),
      'completedSteps': await getCompletedSteps(),
      'progress': await getProgress(),
    };
  }
}
