import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/power_up.dart';

/// Database helper for managing complex game data with SQLite
/// Handles power-up inventory and story level progress
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  /// Get database instance, initializing if necessary
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('blockerino.db');
    return _database!;
  }

  /// Initialize database and create tables
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  /// Create database tables
  Future<void> _createDB(Database db, int version) async {
    // Power-Up Inventory Table
    await db.execute('''
      CREATE TABLE inventory (
        power_up_type TEXT PRIMARY KEY,
        count INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Story Level Progress Table
    await db.execute('''
      CREATE TABLE level_progress (
        level_number INTEGER PRIMARY KEY,
        stars INTEGER NOT NULL DEFAULT 0,
        high_score INTEGER NOT NULL DEFAULT 0,
        completed INTEGER NOT NULL DEFAULT 0,
        last_played TEXT
      )
    ''');

    // Initialize inventory with all power-up types
    for (var powerUp in PowerUp.allPowerUps) {
      await db.insert('inventory', {
        'power_up_type': powerUp.type.name,
        'count': 0,
      });
    }
  }

  // ========== Inventory Operations ==========

  /// Get power-up count from inventory
  Future<int> getPowerUpCount(PowerUpType type) async {
    final db = await database;
    final result = await db.query(
      'inventory',
      columns: ['count'],
      where: 'power_up_type = ?',
      whereArgs: [type.name],
    );

    if (result.isNotEmpty) {
      return result.first['count'] as int;
    }
    return 0;
  }

  /// Get all power-up inventory
  Future<Map<PowerUpType, int>> getAllInventory() async {
    final db = await database;
    final result = await db.query('inventory');

    final inventory = <PowerUpType, int>{};
    for (var row in result) {
      final typeString = row['power_up_type'] as String;
      final count = row['count'] as int;
      
      // Find matching PowerUpType enum
      try {
        final type = PowerUpType.values.firstWhere((e) => e.name == typeString);
        inventory[type] = count;
      } catch (e) {
        // Ignore invalid power-up types
      }
    }

    return inventory;
  }

  /// Add power-ups to inventory
  Future<void> addPowerUp(PowerUpType type, int amount) async {
    final db = await database;
    final currentCount = await getPowerUpCount(type);
    
    await db.update(
      'inventory',
      {'count': currentCount + amount},
      where: 'power_up_type = ?',
      whereArgs: [type.name],
    );
  }

  /// Use (decrement) a power-up from inventory
  Future<bool> usePowerUp(PowerUpType type) async {
    final db = await database;
    final currentCount = await getPowerUpCount(type);

    if (currentCount <= 0) return false;

    await db.update(
      'inventory',
      {'count': currentCount - 1},
      where: 'power_up_type = ?',
      whereArgs: [type.name],
    );

    return true;
  }

  /// Set power-up count directly
  Future<void> setPowerUpCount(PowerUpType type, int count) async {
    final db = await database;
    
    await db.update(
      'inventory',
      {'count': count},
      where: 'power_up_type = ?',
      whereArgs: [type.name],
    );
  }

  // ========== Story Level Progress Operations ==========

  /// Get stars for a specific level
  Future<int> getLevelStars(int levelNumber) async {
    final db = await database;
    final result = await db.query(
      'level_progress',
      columns: ['stars'],
      where: 'level_number = ?',
      whereArgs: [levelNumber],
    );

    if (result.isNotEmpty) {
      return result.first['stars'] as int;
    }
    return 0;
  }

  /// Get all level stars
  Future<Map<int, int>> getAllLevelStars() async {
    final db = await database;
    final result = await db.query('level_progress');

    final stars = <int, int>{};
    for (var row in result) {
      stars[row['level_number'] as int] = row['stars'] as int;
    }

    return stars;
  }

  /// Get total stars earned across all levels
  Future<int> getTotalStars() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(stars) as total FROM level_progress'
    );

    if (result.isNotEmpty && result.first['total'] != null) {
      return result.first['total'] as int;
    }
    return 0;
  }

  /// Update level progress (stars, high score, completion)
  Future<void> updateLevelProgress({
    required int levelNumber,
    required int stars,
    required int score,
  }) async {
    final db = await database;
    
    // Check if level exists
    final existing = await db.query(
      'level_progress',
      where: 'level_number = ?',
      whereArgs: [levelNumber],
    );

    final now = DateTime.now().toIso8601String();

    if (existing.isEmpty) {
      // Insert new level progress
      await db.insert('level_progress', {
        'level_number': levelNumber,
        'stars': stars,
        'high_score': score,
        'completed': stars > 0 ? 1 : 0,
        'last_played': now,
      });
    } else {
      // Update existing - only if new stars/score is better
      final currentStars = existing.first['stars'] as int;
      final currentHighScore = existing.first['high_score'] as int;

      await db.update(
        'level_progress',
        {
          'stars': stars > currentStars ? stars : currentStars,
          'high_score': score > currentHighScore ? score : currentHighScore,
          'completed': 1,
          'last_played': now,
        },
        where: 'level_number = ?',
        whereArgs: [levelNumber],
      );
    }
  }

  /// Get high score for a specific level
  Future<int> getLevelHighScore(int levelNumber) async {
    final db = await database;
    final result = await db.query(
      'level_progress',
      columns: ['high_score'],
      where: 'level_number = ?',
      whereArgs: [levelNumber],
    );

    if (result.isNotEmpty) {
      return result.first['high_score'] as int;
    }
    return 0;
  }

  /// Check if level is completed (has at least 1 star)
  Future<bool> isLevelCompleted(int levelNumber) async {
    final db = await database;
    final result = await db.query(
      'level_progress',
      columns: ['completed'],
      where: 'level_number = ?',
      whereArgs: [levelNumber],
    );

    if (result.isNotEmpty) {
      return (result.first['completed'] as int) == 1;
    }
    return false;
  }

  /// Get count of completed levels
  Future<int> getCompletedLevelsCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM level_progress WHERE completed = 1'
    );

    if (result.isNotEmpty) {
      return result.first['count'] as int;
    }
    return 0;
  }

  // ========== Database Management ==========

  /// Close database connection
  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  /// Delete database (for testing/reset)
  Future<void> deleteDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'blockerino.db');
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }

  /// Reset all data (useful for testing)
  Future<void> resetAllData() async {
    final db = await database;
    
    // Reset inventory
    await db.delete('inventory');
    for (var powerUp in PowerUp.allPowerUps) {
      await db.insert('inventory', {
        'power_up_type': powerUp.type.name,
        'count': 0,
      });
    }

    // Reset level progress
    await db.delete('level_progress');
  }

  /// Clear all data from database (for settings clear data feature)
  Future<void> clearAllData() async {
    final db = await database;
    
    // Clear all tables
    await db.delete('inventory');
    await db.delete('level_progress');
  }
}
