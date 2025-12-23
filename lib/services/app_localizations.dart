import 'package:flutter/material.dart';

/// Centralized localization service for the app
/// Supports English, Chinese, and Khmer languages
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // App Name & General
      'app_name': 'BLOCKERINO',
      'app_tagline': '8x8 grid, break lines!',
      
      // Main Menu
      'classic_mode': 'CLASSIC',
      'classic_subtitle': '8×8 Grid • Match Lines',
      'chaos_mode': 'CHAOS MODE',
      'chaos_subtitle': '10×10 Grid • 5 Pieces',
      'story_mode': 'STORY MODE',
      'story_subtitle': 'Progress Through Levels',
      'daily_challenge': 'DAILY CHALLENGE',
      'daily_subtitle': 'Today\'s Challenge',
      'store': 'STORE',
      'store_subtitle': 'Power-Ups & Themes',
      'leaderboard': 'LEADERBOARD',
      'settings': 'SETTINGS',
      'sign_in': 'Sign In',
      'guest_player': 'Guest Player',
      'tap_to_sign_in': 'Tap to sign in',
      
      // Game UI
      'score': 'Score',
      'high_score': 'High Score',
      'moves': 'Moves',
      'moves_left': 'moves left',
      'level': 'Level',
      'target': 'Target',
      'coins': 'Coins',
      'combo': 'COMBO',
      'objectives': 'OBJECTIVES',
      'complete': '✓ COMPLETE',
      'score_label': 'Score:',
      'lines_label': 'Lines:',
      
      // Game Over
      'game_over': 'GAME OVER',
      'final_score': 'Final Score',
      'new_high_score': 'New High Score!',
      'play_again': 'Play Again',
      'main_menu': 'Main Menu',
      
      // Power-Ups
      'power_ups': 'Power-Ups',
      'bomb': 'Bomb',
      'wild_piece': 'Wild Piece',
      'line_clear': 'Line Clear',
      'color_bomb': 'Color Bomb',
      'shuffle': 'Shuffle',
      'use': 'Use',
      'buy': 'Buy',
      
      // Store
      'themes': 'Themes',
      'purchase': 'Purchase',
      'equipped': 'Equipped',
      'locked': 'Locked',
      'classic_theme': 'Classic',
      'neon_theme': 'Neon',
      'nature_theme': 'Nature',
      'galaxy_theme': 'Galaxy',
      
      // Settings
      'game_settings': 'Game Settings',
      'sound': 'Sound',
      'haptics': 'Haptics',
      'animations': 'Animations',
      'account': 'Account',
      'appearance': 'Appearance',
      'current_theme': 'Current Theme',
      'browse_themes': 'Browse Themes',
      'statistics': 'Statistics',
      'total_coins': 'Total Coins',
      'story_progress': 'Story Progress',
      'themes_unlocked': 'Themes Unlocked',
      'data_management': 'Data Management',
      'sync_data': 'Sync Data',
      'clear_all_data': 'Clear All Data',
      'app_info': 'App Info',
      'version': 'Version',
      'sign_out': 'Sign Out',
      
      // Dialogs
      'confirm': 'Confirm',
      'cancel': 'Cancel',
      'ok': 'OK',
      'yes': 'Yes',
      'no': 'No',
      'warning': 'Warning',
      'sign_in_prompt': 'Sign in to sync your progress across devices and compete on the global leaderboard!',
      'sign_out_confirm': 'Are you sure you want to sign out?',
      'clear_data_warning': 'This will delete all your game progress, inventory, and settings. This action cannot be undone!',
      'clear_data_confirm': 'Are you sure you want to clear all data?',
      
      // Story Mode
      'locked_level': 'Locked',
      'completed': 'Completed',
      'play': 'Play',
      'replay': 'Replay',
      'stars': 'Stars',
      'reward': 'Reward',
      
      // Leaderboard
      'all_time': 'All Time',
      'this_week': 'This Week',
      'your_rank': 'Your Rank',
      'rank': 'Rank',
      'player': 'Player',
      'no_scores': 'No scores yet',
      'sign_in_to_compete': 'Sign in to compete on the leaderboard!',
      
      // Achievements
      'achievement_unlocked': 'Achievement Unlocked!',
      'continue': 'Continue',
      
      // Errors
      'error': 'Error',
      'network_error': 'Network error. Please check your connection.',
      'sign_in_failed': 'Sign in failed. Please try again.',
      'purchase_failed': 'Purchase failed. Please try again.',
      'insufficient_coins': 'Insufficient coins!',
    },
    
    'zh': {
      // App Name & General
      'app_name': 'BLOCKERINO',
      'app_tagline': '8x8 网格，消除线条！',
      
      // Main Menu
      'classic_mode': '经典模式',
      'classic_subtitle': '8×8 网格 • 匹配线条',
      'chaos_mode': '混乱模式',
      'chaos_subtitle': '10×10 网格 • 5 个方块',
      'story_mode': '故事模式',
      'story_subtitle': '通关关卡',
      'daily_challenge': '每日挑战',
      'daily_subtitle': '今日挑战',
      'store': '商店',
      'store_subtitle': '道具和主题',
      'leaderboard': '排行榜',
      'settings': '设置',
      'sign_in': '登录',
      'guest_player': '游客',
      'tap_to_sign_in': '点击登录',
      
      // Game UI
      'score': '分数',
      'high_score': '最高分',
      'moves': '步数',
      'moves_left': '剩余步数',
      'level': '关卡',
      'target': '目标',
      'coins': '金币',
      'combo': '连击',
      'objectives': '目标',
      'complete': '✓ 完成',
      'score_label': '分数：',
      'lines_label': '行数：',
      
      // Game Over
      'game_over': '游戏结束',
      'final_score': '最终得分',
      'new_high_score': '新纪录！',
      'play_again': '再玩一次',
      'main_menu': '主菜单',
      
      // Power-Ups
      'power_ups': '道具',
      'bomb': '炸弹',
      'wild_piece': '万能块',
      'line_clear': '消除线',
      'color_bomb': '彩色炸弹',
      'shuffle': '洗牌',
      'use': '使用',
      'buy': '购买',
      
      // Store
      'themes': '主题',
      'purchase': '购买',
      'equipped': '已装备',
      'locked': '已锁定',
      'classic_theme': '经典',
      'neon_theme': '霓虹',
      'nature_theme': '自然',
      'galaxy_theme': '星系',
      
      // Settings
      'game_settings': '游戏设置',
      'sound': '声音',
      'haptics': '触觉反馈',
      'animations': '动画',
      'account': '账户',
      'appearance': '外观',
      'current_theme': '当前主题',
      'browse_themes': '浏览主题',
      'statistics': '统计',
      'total_coins': '总金币',
      'story_progress': '故事进度',
      'themes_unlocked': '已解锁主题',
      'data_management': '数据管理',
      'sync_data': '同步数据',
      'clear_all_data': '清除所有数据',
      'app_info': '应用信息',
      'version': '版本',
      'sign_out': '登出',
      
      // Dialogs
      'confirm': '确认',
      'cancel': '取消',
      'ok': '确定',
      'yes': '是',
      'no': '否',
      'warning': '警告',
      'sign_in_prompt': '登录以在设备之间同步进度并在全球排行榜上竞争！',
      'sign_out_confirm': '确定要登出吗？',
      'clear_data_warning': '这将删除您的所有游戏进度、库存和设置。此操作无法撤消！',
      'clear_data_confirm': '确定要清除所有数据吗？',
      
      // Story Mode
      'locked_level': '已锁定',
      'completed': '已完成',
      'play': '开始',
      'replay': '重玩',
      'stars': '星星',
      'reward': '奖励',
      
      // Leaderboard
      'all_time': '全部时间',
      'this_week': '本周',
      'your_rank': '您的排名',
      'rank': '排名',
      'player': '玩家',
      'no_scores': '暂无分数',
      'sign_in_to_compete': '登录以参加排行榜竞争！',
      
      // Achievements
      'achievement_unlocked': '成就解锁！',
      'continue': '继续',
      
      // Errors
      'error': '错误',
      'network_error': '网络错误。请检查您的连接。',
      'sign_in_failed': '登录失败。请重试。',
      'purchase_failed': '购买失败。请重试。',
      'insufficient_coins': '金币不足！',
    },
    
    'km': {
      // App Name & General (Khmer)
      'app_name': 'BLOCKERINO',
      'app_tagline': '8x8 ក្រឡា, លុបបន្ទាត់!',
      
      // Main Menu
      'classic_mode': 'ប្រពៃណី',
      'classic_subtitle': '8×8 ក្រឡា • ផ្គូផ្គងបន្ទាត់',
      'chaos_mode': 'របៀបចម្រុះ',
      'chaos_subtitle': '10×10 ក្រឡា • 5 ដុំ',
      'story_mode': 'របៀបរឿង',
      'story_subtitle': 'វឌ្ឍនភាពតាមកម្រិត',
      'daily_challenge': 'បញ្ហាប្រចាំថ្ងៃ',
      'daily_subtitle': 'បញ្ហាថ្ងៃនេះ',
      'store': 'ហាង',
      'store_subtitle': 'ពាក់កណ្តាលភាព & ស្បែក',
      'leaderboard': 'តារាងឈ្នះ',
      'settings': 'ការកំណត់',
      'sign_in': 'ចូល',
      'guest_player': 'អ្នកលេងភ្ញៀវ',
      'tap_to_sign_in': 'ចុចដើម្បីចូល',
      
      // Game UI
      'score': 'ពិន្ទុ',
      'high_score': 'ពិន្ទុខ្ពស់',
      'moves': 'ចំនួនគូរ',
      'moves_left': 'ចំនួនគូរនៅសល់',
      'level': 'កម្រិត',
      'target': 'គោលដៅ',
      'coins': 'កាក់',
      'combo': 'ការបន្ត',
      'objectives': 'គោលដៅ',
      'complete': '✓ បញ្ចប់',
      'score_label': 'ពិន្ទុ៖',
      'lines_label': 'បន្ទាត់៖',
      
      // Game Over
      'game_over': 'ចប់ហ្គេម',
      'final_score': 'ពិន្ទុចុងក្រោយ',
      'new_high_score': 'កំណត់ត្រាថ្មី!',
      'play_again': 'លេងម្តងទៀត',
      'main_menu': 'ម៉ឺនុយមេ',
      
      // Power-Ups
      'power_ups': 'ពាក់កណ្តាលភាព',
      'bomb': 'គ្រាប់បែក',
      'wild_piece': 'ដុំព្រៃ',
      'line_clear': 'លុបបន្ទាត់',
      'color_bomb': 'គ្រាប់បែកពណ៌',
      'shuffle': 'សាប',
      'use': 'ប្រើ',
      'buy': 'ទិញ',
      
      // Store
      'themes': 'ស្បែក',
      'purchase': 'ទិញ',
      'equipped': 'បានតំឡើង',
      'locked': 'ចាក់សោ',
      'classic_theme': 'ប្រពៃណី',
      'neon_theme': 'នីអុន',
      'nature_theme': 'ធម្មជាតិ',
      'galaxy_theme': 'កាឡាក់ស៊ី',
      
      // Settings
      'game_settings': 'ការកំណត់ហ្គេម',
      'sound': 'សំឡេង',
      'haptics': 'ការរំញ័រ',
      'animations': 'ចលនា',
      'account': 'គណនី',
      'appearance': 'រូបរាង',
      'current_theme': 'ស្បែកបច្ចុប្បន្ន',
      'browse_themes': 'រកមើលស្បែក',
      'statistics': 'ស្ថិតិ',
      'total_coins': 'សរុបកាក់',
      'story_progress': 'វឌ្ឍនភាពរឿង',
      'themes_unlocked': 'ស្បែកដោះសោ',
      'data_management': 'គ្រប់គ្រងទិន្នន័យ',
      'sync_data': 'ធ្វើសមកាលកម្មទិន្នន័យ',
      'clear_all_data': 'លុបទិន្នន័យទាំងអស់',
      'app_info': 'ព័ត៌មានកម្មវិធី',
      'version': 'កំណែ',
      'sign_out': 'ចាកចេញ',
      
      // Dialogs
      'confirm': 'បញ្ជាក់',
      'cancel': 'បោះបង់',
      'ok': 'យល់ព្រម',
      'yes': 'បាទ/ចាស',
      'no': 'ទេ',
      'warning': 'ការព្រមាន',
      'sign_in_prompt': 'ចូលដើម្បីធ្វើសមកាលកម្មវឌ្ឍនភាពរបស់អ្នកនៅលើឧបករណ៍ផ្សេងៗ និងប្រកួតប្រជែងនៅលើតារាងឈ្នះសកល!',
      'sign_out_confirm': 'តើអ្នកប្រាកដថាចង់ចាកចេញមែនទេ?',
      'clear_data_warning': 'នេះនឹងលុបវឌ្ឍនភាពហ្គេម សារពើភណ្ឌ និងការកំណត់ទាំងអស់របស់អ្នក។ សកម្មភាពនេះមិនអាចត្រឡប់វិញបានទេ!',
      'clear_data_confirm': 'តើអ្នកប្រាកដថាចង់លុបទិន្នន័យទាំងអស់មែនទេ?',
      
      // Story Mode
      'locked_level': 'ចាក់សោ',
      'completed': 'បញ្ចប់',
      'play': 'លេង',
      'replay': 'លេងម្តងទៀត',
      'stars': 'ផ្កាយ',
      'reward': 'រង្វាន់',
      
      // Leaderboard
      'all_time': 'គ្រប់ពេល',
      'this_week': 'សប្តាហ៍នេះ',
      'your_rank': 'ចំណាត់ថ្នាក់របស់អ្នក',
      'rank': 'ចំណាត់ថ្នាក់',
      'player': 'អ្នកលេង',
      'no_scores': 'មិនទាន់មានពិន្ទុ',
      'sign_in_to_compete': 'ចូលដើម្បីប្រកួតប្រជែងនៅលើតារាងឈ្នះ!',
      
      // Achievements
      'achievement_unlocked': 'ដោះសោសមិទ្ធិផលបាន!',
      'continue': 'បន្ត',
      
      // Errors
      'error': 'កំហុស',
      'network_error': 'កំហុសបណ្តាញ។ សូមពិនិត្យការតភ្ជាប់របស់អ្នក។',
      'sign_in_failed': 'ការចូលបរាជ័យ។ សូមព្យាយាមម្តងទៀត។',
      'purchase_failed': 'ការទិញបរាជ័យ។ សូមព្យាយាមម្តងទៀត។',
      'insufficient_coins': 'កាក់មិនគ្រប់គ្រាន់!',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
  
  // Convenience getters for common translations
  String get appName => translate('app_name');
  String get appTagline => translate('app_tagline');
  String get classicMode => translate('classic_mode');
  String get chaosMode => translate('chaos_mode');
  String get storyMode => translate('story_mode');
  String get dailyChallenge => translate('daily_challenge');
  String get store => translate('store');
  String get leaderboard => translate('leaderboard');
  String get settings => translate('settings');
  String get signIn => translate('sign_in');
  String get guestPlayer => translate('guest_player');
  String get score => translate('score');
  String get highScore => translate('high_score');
  String get coins => translate('coins');
  String get gameOver => translate('game_over');
  String get playAgain => translate('play_again');
  String get mainMenu => translate('main_menu');
  String get confirm => translate('confirm');
  String get cancel => translate('cancel');
  String get ok => translate('ok');
  String get warning => translate('warning');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'zh', 'km'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
