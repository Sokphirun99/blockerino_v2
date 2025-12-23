# Story Mode Implementation

## Overview
Story mode now has unique gameplay mechanics that differentiate it from classic mode. Each level can have time limits, objectives, restrictions, and star-based ratings.

## ✅ Implemented Features

### 1. **Time Limits** ⏱️
- Levels with `timeLimit` property now display a countdown timer in the HUD
- Timer changes color to red when 10 seconds or less remain
- Game automatically ends when time runs out
- Format: MM:SS display

### 2. **Objectives Tracking** 🎯
- Real-time display of level objectives in the game HUD
- Supports two objective types:
  - **Target Score**: Reach a specific score to complete the level
  - **Target Lines**: Clear a specific number of lines to complete the level
- Visual checkmarks show when objectives are completed
- Game automatically ends when any objective is met

### 3. **Star Rating System** ⭐
- 3-star rating based on final score:
  - 1 star: score ≥ `starThreshold1`
  - 2 stars: score ≥ `starThreshold2`
  - 3 stars: score ≥ `starThreshold3`
- Stars displayed in completion dialog
- Progress is saved with star count

### 4. **Power-Up Restrictions** 🚫
- Levels can disable power-ups via `restrictions` property
- Example: "No power-ups" or "Without power-ups"
- Power-up button becomes non-functional when disabled
- Indicated by `powerUpsDisabled` flag in game state

### 5. **Level Completion Dialog** 🏆
- **Success**: Shows "LEVEL COMPLETE!" with star rating
- **Failure**: Shows "GAME OVER" if objectives not met or time runs out
- Automatically awards coins on successful completion
- Different visual styles for success vs failure

## Technical Implementation

### Modified Files

#### 1. `lib/cubits/game/game_state.dart`
- Added story mode fields to `GameInProgress`:
  - `storyLevel`: Current level data
  - `linesCleared`: Total lines cleared this session
  - `timeRemaining`: Countdown timer (seconds)
  - `powerUpsDisabled`: Restriction flag
- Updated `GameOver` state:
  - `storyLevel`: Level data for completion screen
  - `starsEarned`: 0-3 based on score thresholds
  - `levelCompleted`: true if objectives met

#### 2. `lib/cubits/game/game_cubit.dart`
- `startGame()` now accepts optional `StoryLevel` parameter
- `_startStoryGame()`: Initializes story-specific game state
- `_startStoryTimer()`: Manages countdown timer with 1-second intervals
- `_endStoryLevel()`: Calculates stars and handles completion/failure
- `placePiece()`: Now checks story objectives after each move
- `triggerPowerUp()`: Respects power-up restrictions
- Timer automatically cancels on completion or navigation away

#### 3. `lib/screens/game_screen.dart`
- Passes `storyLevel` to `gameCubit.startGame()`
- `_showGameOverDialog()`: Uses state data for star display
- Proper cleanup of story mode data

#### 4. `lib/widgets/game_hud_widget.dart`
- Added time limit display (changes color when low)
- Added objectives panel showing:
  - Score progress: "🎯 Score: 1250/2000"
  - Lines progress: "📊 Lines: 8/10"
- Helper methods:
  - `_formatTime()`: Converts seconds to MM:SS
  - `_buildObjective()`: Creates objective rows with checkmarks

## Game Flow

### Starting a Story Level
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => GameScreen(
      storyLevel: StoryLevel.allLevels[0], // Level 1
    ),
  ),
);
```

### During Gameplay
1. Timer counts down (if applicable)
2. Objectives are tracked in real-time
3. HUD displays progress
4. Game ends when:
   - ✅ Score target reached
   - ✅ Line target reached
   - ❌ Time runs out
   - ❌ No valid moves remaining

### Level Completion
1. Stars calculated based on final score
2. Coins awarded automatically
3. Progress saved to settings
4. Completion dialog shows results

## Example Story Level

```dart
const StoryLevel(
  levelNumber: 1,
  title: 'First Steps',
  description: 'Learn the basics',
  story: 'Welcome to Blockerino!',
  gameMode: GameMode.story,
  difficulty: LevelDifficulty.easy,
  targetScore: 500,        // Primary objective
  targetLines: 5,          // Alternative objective
  timeLimit: 120,          // 2 minutes
  restrictions: [],        // No restrictions
  starThreshold1: 500,     // 1 star
  starThreshold2: 800,     // 2 stars
  starThreshold3: 1000,    // 3 stars
  coinReward: 50,
  isUnlocked: true,
)
```

## Key Differences from Classic Mode

| Feature | Classic Mode | Story Mode |
|---------|-------------|------------|
| Time Limit | None | Optional (per level) |
| Objectives | Endless high score | Score/Line targets |
| Power-Ups | Always available | Can be disabled |
| Completion | Game Over only | Success + Star rating |
| Save/Load | Full save system | No save (fresh start) |
| Rewards | High score only | Coins + Stars |

## Testing Checklist

- [x] Time limit countdown works correctly
- [x] Timer turns red at 10 seconds
- [x] Game ends when timer reaches 0
- [x] Score objectives trigger completion
- [x] Line objectives trigger completion
- [x] Stars calculated correctly
- [x] Power-up restrictions enforced
- [x] Completion dialog shows proper data
- [x] Coins awarded on success
- [x] Progress saved to settings
- [x] No crashes on level completion
- [x] Chrome deployment successful

## Future Enhancements

- [ ] Add more restriction types (e.g., "Only 2 pieces per hand")
- [ ] Track level completion time for speed bonuses
- [ ] Add combo-based objectives
- [ ] Implement perfect clear objectives
- [ ] Add level unlock progression (Level 2 unlocks after Level 1)
- [ ] Create level select screen with star display
- [ ] Add level replay to improve star ratings

## Notes

- Story mode uses 8x8 board (same as classic)
- Hand size is 3 pieces (same as classic)
- All 30 levels are defined in `story_level.dart`
- Firebase warning on web is expected (no web config)
- Android Java error is existing (requires VS Code restart)
