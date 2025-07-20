import '../models/app_info.dart';
import '../utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class AppUsageService {
  static final AppUsageService _instance = AppUsageService._internal();
  factory AppUsageService() => _instance;
  AppUsageService._internal();

  // Get default blocked apps
  Future<List<AppInfo>> getDefaultBlockedApps() async {
    return AppConstants.defaultBlockedApps
        .map((app) => AppInfo(
              packageName: app['packageName']!,
              appName: app['appName']!,
              isBlocked: true,
              usageTimeMinutes: 0,
            ))
        .toList();
  }

  // Get all available apps (default + common apps)
  Future<List<AppInfo>> getAllApps() async {
    final defaultApps = await getDefaultBlockedApps();
    
    // Add common apps that users might want to block
    final commonApps = [
      AppInfo(
        packageName: 'com.google.android.youtube',
        appName: 'YouTube',
        isBlocked: false,
        usageTimeMinutes: 0,
      ),
      AppInfo(
        packageName: 'com.spotify.music',
        appName: 'Spotify',
        isBlocked: false,
        usageTimeMinutes: 0,
      ),
      AppInfo(
        packageName: 'com.netflix.mediaclient',
        appName: 'Netflix',
        isBlocked: false,
        usageTimeMinutes: 0,
      ),
      AppInfo(
        packageName: 'com.discord',
        appName: 'Discord',
        isBlocked: false,
        usageTimeMinutes: 0,
      ),
      AppInfo(
        packageName: 'com.reddit.frontpage',
        appName: 'Reddit',
        isBlocked: false,
        usageTimeMinutes: 0,
      ),
      AppInfo(
        packageName: 'com.google.android.gm',
        appName: 'Gmail',
        isBlocked: false,
        usageTimeMinutes: 0,
      ),
      AppInfo(
        packageName: 'com.google.android.apps.maps',
        appName: 'Google Maps',
        isBlocked: false,
        usageTimeMinutes: 0,
      ),
      AppInfo(
        packageName: 'com.google.android.apps.photos',
        appName: 'Google Photos',
        isBlocked: false,
        usageTimeMinutes: 0,
      ),
    ];

    return [...defaultApps, ...commonApps];
  }

  // Get apps by category from a given list
  Future<List<AppInfo>> getAppsByCategory(String category, {List<AppInfo>? appsList}) async {
    final allApps = appsList ?? await getAllApps();
    print('AppUsageService: getAppsByCategory - category: $category, total apps: ${allApps.length}');
    
    List<AppInfo> result;
    switch (category.toLowerCase()) {
      case 'social':
        result = allApps.where((app) => _isSocialMediaApp(app.packageName)).toList();
        break;
      case 'entertainment':
        result = allApps.where((app) => _isEntertainmentApp(app.packageName)).toList();
        break;
      case 'productivity':
        result = allApps.where((app) => _isProductivityApp(app.packageName)).toList();
        break;
      case 'gaming':
        result = allApps.where((app) => _isGamingApp(app.packageName)).toList();
        break;
      case 'communication':
        result = allApps.where((app) => _isCommunicationApp(app.packageName)).toList();
        break;
      case 'shopping':
        result = allApps.where((app) => _isShoppingApp(app.packageName)).toList();
        break;
      case 'news':
        result = allApps.where((app) => _isNewsApp(app.packageName)).toList();
        break;
      case 'education':
        result = allApps.where((app) => _isEducationApp(app.packageName)).toList();
        break;
      case 'finance':
        result = allApps.where((app) => _isFinanceApp(app.packageName)).toList();
        break;
      case 'health':
        result = allApps.where((app) => _isHealthApp(app.packageName)).toList();
        break;
      case 'travel':
        result = allApps.where((app) => _isTravelApp(app.packageName)).toList();
        break;
      case 'utilities':
        result = allApps.where((app) => _isUtilitiesApp(app.packageName)).toList();
        break;
      default:
        result = allApps;
        break;
    }
    
    print('AppUsageService: $category category - found ${result.length} apps');
    return result;
  }

  // Check if app is social media
  bool _isSocialMediaApp(String packageName) {
    final socialMediaPackages = [
      'com.facebook.katana',
      'com.instagram.android',
      'com.zhiliaoapp.musically',
      'com.twitter.android',
      'com.threads.android',
      'com.snapchat.android',
      'com.whatsapp',
      'com.telegram.messenger',
      'com.discord',
      'com.reddit.frontpage',
      'com.pinterest',
      'com.linkedin.android',
    ];
    return socialMediaPackages.contains(packageName);
  }

  // Check if app is entertainment
  bool _isEntertainmentApp(String packageName) {
    final entertainmentPackages = [
      'com.spotify.music',
      'com.netflix.mediaclient',
      'com.google.android.youtube',
      'com.amazon.avod.thirdpartyclient',
      'com.hulu.plus',
      'com.disney.disneyplus',
    ];
    return entertainmentPackages.contains(packageName);
  }

  // Check if app is productivity
  bool _isProductivityApp(String packageName) {
    final productivityPackages = [
      'com.microsoft.office.word',
      'com.microsoft.office.excel',
      'com.microsoft.office.powerpoint',
      'com.google.android.apps.docs.editors.docs',
      'com.google.android.apps.docs.editors.sheets',
      'com.google.android.apps.docs.editors.slides',
      'com.notion.id',
      'com.trello',
      'com.asana.app',
      'com.google.android.gm',
      'com.slack',
      'com.microsoft.teams',
      'com.zoom.us',
      'com.google.android.apps.meetings',
      'com.dropbox.android',
      'com.google.android.apps.drive',
      'com.evernote',
      'com.wunderlist.android',
      'com.todoist',
      'com.any.do',
    ];
    return productivityPackages.contains(packageName);
  }

  // Check if app is gaming
  bool _isGamingApp(String packageName) {
    final gamingPackages = [
      'com.activision.callofduty.shooter',
      'com.epicgames.fortnite',
      'com.roblox.client',
      'com.mojang.minecraftpe',
      'com.nianticlabs.pokemongo',
      'com.supercell.clashofclans',
      'com.supercell.clashroyale',
      'com.supercell.brawlstars',
      'com.king.candycrushsaga',
      'com.king.candycrushsoda',
      'com.ea.gp.fifamobile',
      'com.ea.gp.nbalive',
      'com.tencent.ig',
      'com.tencent.tmgp.pubgmhd',
      'com.gametion.freefire',
      'com.garena.game.kgvn',
      'com.vng.g6.a',
      'com.vng.g6.b',
      'com.vng.g6.c',
      'com.vng.g6.d',
    ];
    return gamingPackages.contains(packageName);
  }

  // Check if app is communication
  bool _isCommunicationApp(String packageName) {
    final communicationPackages = [
      'com.whatsapp',
      'com.telegram.messenger',
      'com.skype.raider',
      'com.viber.voip',
      'com.linecorp.LGTALK',
      'com.tencent.mm',
      'com.tencent.mobileqq',
      'com.tencent.tim',
      'com.tencent.qq',
      'com.tencent.qqmusic',
      'com.tencent.qqsport',
      'com.tencent.qqnews',
      'com.tencent.qqreader',
      'com.tencent.qqpimsecure',
      'com.tencent.qqgame',
      'com.tencent.qqvideo',
      'com.tencent.qqmail',
      'com.tencent.qqbrowser',
      'com.tencent.qqpinyin',
      'com.tencent.qqinput',
    ];
    return communicationPackages.contains(packageName);
  }

  // Check if app is shopping
  bool _isShoppingApp(String packageName) {
    final shoppingPackages = [
      'com.amazon.shopping',
      'com.ebay.mobile',
      'com.alibaba.aliexpresshd',
      'com.taobao.taobao',
      'com.taobao.lite',
      'com.taobao.wireless',
      'com.taobao.tmall',
      'com.taobao.tmall.lite',
      'com.taobao.tmall.wireless',
      'com.taobao.tmall.hd',
      'com.taobao.tmall.lite.hd',
      'com.taobao.tmall.wireless.hd',
      'com.taobao.tmall.lite.wireless',
      'com.taobao.tmall.lite.wireless.hd',
      'com.taobao.tmall.lite.wireless.hd.lite',
      'com.taobao.tmall.lite.wireless.hd.lite.wireless',
      'com.taobao.tmall.lite.wireless.hd.lite.wireless.hd',
      'com.taobao.tmall.lite.wireless.hd.lite.wireless.hd.lite',
      'com.taobao.tmall.lite.wireless.hd.lite.wireless.hd.lite.wireless',
      'com.taobao.tmall.lite.wireless.hd.lite.wireless.hd.lite.wireless.hd',
    ];
    return shoppingPackages.contains(packageName);
  }

  // Check if app is news
  bool _isNewsApp(String packageName) {
    final newsPackages = [
      'com.google.android.apps.news',
      'com.nytimes.android',
      'com.washingtonpost.rainbow',
      'com.bbc.news',
      'com.cnn.mobile.android.phone',
      'com.reuters.news',
      'com.bloomberg.news',
      'com.ft.mobile.alpha',
      'com.economist.lamarr',
      'com.medium.reader',
      'com.quora.android',
      'com.reddit.frontpage',
      'com.reddit.launch',
      'com.reddit.app',
      'com.reddit.inc',
      'com.reddit.beta',
      'com.reddit.alpha',
      'com.reddit.dev',
      'com.reddit.debug',
      'com.reddit.test',
    ];
    return newsPackages.contains(packageName);
  }

  // Check if app is education
  bool _isEducationApp(String packageName) {
    final educationPackages = [
      'org.khanacademy.android',
      'com.duolingo',
      'com.memrise.android.memrisecompanion',
      'com.babbel.mobile.android.en',
      'com.rosettastone.android',
      'com.udacity.android',
      'com.coursera.android',
      'com.edx.android',
      'com.skillshare.android',
      'com.udemy.android',
      'com.lynda.android',
      'com.pluralsight.android',
      'com.codecademy.android',
      'com.freecodecamp.android',
      'com.sololearn.android',
      'com.grasshopper.app',
      'com.mimo.android',
      'com.programminghub.android',
      'com.coding.android',
      'com.learn.android',
    ];
    return educationPackages.contains(packageName);
  }

  // Check if app is finance
  bool _isFinanceApp(String packageName) {
    final financePackages = [
      'com.paypal.android.p2pmobile',
      'com.venmo',
      'com.square.cash',
      'com.stripe.android',
      'com.coinbase.android',
      'com.binance.dev',
      'com.robinhood.android',
      'com.td.ameritrade.mobile',
      'com.etrade.mobile',
      'com.fidelity.android',
      'com.schwab.mobile',
      'com.vanguard.mobile',
      'com.mint',
      'com.youneedabudget',
      'com.personalcapital',
      'com.acorns.android',
      'com.stashinvest',
      'com.wealthfront',
      'com.betterment',
      'com.sofi',
    ];
    return financePackages.contains(packageName);
  }

  // Check if app is health
  bool _isHealthApp(String packageName) {
    final healthPackages = [
      'com.fitbit.FitbitMobile',
      'com.garmin.android.apps.connectmobile',
      'com.polar.polarexercise',
      'com.samsung.android.health',
      'com.huawei.health',
      'com.xiaomi.hm.health',
      'com.oppo.health',
      'com.vivo.health',
      'com.oneplus.health',
      'com.lenovo.health',
      'com.sony.health',
      'com.lge.health',
      'com.motorola.health',
      'com.nokia.health',
      'com.htc.health',
      'com.asus.health',
      'com.zte.health',
      'com.alcatel.health',
      'com.tcl.health',
      'com.blackberry.health',
    ];
    return healthPackages.contains(packageName);
  }

  // Check if app is travel
  bool _isTravelApp(String packageName) {
    final travelPackages = [
      'com.google.android.apps.maps',
      'com.waze',
      'com.uber',
      'com.lyft',
      'com.airbnb.android',
      'com.booking',
      'com.expedia.bookings',
      'com.hotels',
      'com.tripadvisor.android',
      'com.yelp.android',
      'com.foursquare.android',
      'com.google.android.apps.travel',
      'com.google.android.apps.travel.booking',
      'com.google.android.apps.travel.flights',
      'com.google.android.apps.travel.hotels',
      'com.google.android.apps.travel.things',
      'com.google.android.apps.travel.explore',
      'com.google.android.apps.travel.trips',
      'com.google.android.apps.travel.offline',
      'com.google.android.apps.travel.weather',
    ];
    return travelPackages.contains(packageName);
  }

  // Check if app is utilities
  bool _isUtilitiesApp(String packageName) {
    final utilitiesPackages = [
      'com.google.android.apps.photos',
      'com.google.android.apps.docs',
      'com.google.android.apps.drive',
      'com.google.android.apps.calendar',
      'com.google.android.apps.contacts',
      'com.google.android.apps.clock',
      'com.google.android.apps.calculator',
      'com.google.android.apps.translate',
      'com.google.android.apps.translate.offline',
      'com.google.android.apps.translate.voice',
      'com.google.android.apps.translate.camera',
      'com.google.android.apps.translate.conversation',
      'com.google.android.apps.translate.typing',
      'com.google.android.apps.translate.handwriting',
      'com.google.android.apps.translate.instant',
      'com.google.android.apps.translate.offline.voice',
      'com.google.android.apps.translate.offline.camera',
      'com.google.android.apps.translate.offline.conversation',
      'com.google.android.apps.translate.offline.typing',
      'com.google.android.apps.translate.offline.handwriting',
    ];
    return utilitiesPackages.contains(packageName);
  }

  // Get app icon data (returns null for now, can be extended later)
  Future<String?> getAppIconPath(String packageName) async {
    // For now, return null as we don't have direct access to app icons
    // This can be extended later with native Android implementation
    return null;
  }

  // Check if app is installed (simplified check)
  Future<bool> isAppInstalled(String packageName) async {
    // For now, assume all apps in our list are installed
    // This can be extended later with native Android implementation
    final allApps = await getAllApps();
    return allApps.any((app) => app.packageName == packageName);
  }

  // Get app usage statistics for a specific period
  Future<Map<String, Duration>> getAppUsageForPeriod(String period) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    // Mock data for demonstration - in real app, this would come from system usage stats
    final mockUsageData = {
      'today': {
        'Facebook': const Duration(minutes: 45),
        'Instagram': const Duration(minutes: 30),
        'YouTube': const Duration(minutes: 60),
        'TikTok': const Duration(minutes: 25),
        'WhatsApp': const Duration(minutes: 20),
        'Gmail': const Duration(minutes: 15),
      },
      'week': {
        'Facebook': const Duration(hours: 3, minutes: 30),
        'Instagram': const Duration(hours: 2, minutes: 15),
        'YouTube': const Duration(hours: 4, minutes: 45),
        'TikTok': const Duration(hours: 1, minutes: 50),
        'WhatsApp': const Duration(hours: 1, minutes: 30),
        'Gmail': const Duration(minutes: 45),
        'Spotify': const Duration(hours: 2, minutes: 20),
        'Netflix': const Duration(hours: 1, minutes: 15),
      },
      'month': {
        'Facebook': const Duration(hours: 12, minutes: 30),
        'Instagram': const Duration(hours: 8, minutes: 45),
        'YouTube': const Duration(hours: 15, minutes: 20),
        'TikTok': const Duration(hours: 6, minutes: 15),
        'WhatsApp': const Duration(hours: 5, minutes: 30),
        'Gmail': const Duration(hours: 2, minutes: 15),
        'Spotify': const Duration(hours: 8, minutes: 45),
        'Netflix': const Duration(hours: 4, minutes: 30),
        'Discord': const Duration(hours: 3, minutes: 20),
        'Reddit': const Duration(hours: 2, minutes: 15),
      },
    };

    return Map<String, Duration>.from(mockUsageData[period] ?? {});
  }

  // Get app usage by category for a period
  Future<Map<String, Duration>> getAppUsageByCategory(String period, String category) async {
    final allUsage = await getAppUsageForPeriod(period);
    final Map<String, Duration> categoryUsage = {};

    for (final entry in allUsage.entries) {
      final packageName = entry.key;
      final duration = entry.value;

      bool isInCategory = false;
      switch (category.toLowerCase()) {
        case 'social':
          isInCategory = _isSocialMediaApp(packageName);
          break;
        case 'entertainment':
          isInCategory = _isEntertainmentApp(packageName);
          break;
        case 'productivity':
          isInCategory = _isProductivityApp(packageName);
          break;
        case 'gaming':
          isInCategory = _isGamingApp(packageName);
          break;
        case 'communication':
          isInCategory = _isCommunicationApp(packageName);
          break;
        case 'shopping':
          isInCategory = _isShoppingApp(packageName);
          break;
        case 'news':
          isInCategory = _isNewsApp(packageName);
          break;
        case 'education':
          isInCategory = _isEducationApp(packageName);
          break;
        case 'finance':
          isInCategory = _isFinanceApp(packageName);
          break;
        case 'health':
          isInCategory = _isHealthApp(packageName);
          break;
        case 'travel':
          isInCategory = _isTravelApp(packageName);
          break;
        case 'utilities':
          isInCategory = _isUtilitiesApp(packageName);
          break;
      }

      if (isInCategory) {
        categoryUsage[packageName] = duration;
      }
    }

    return categoryUsage;
  }

  // Get total usage time for a period
  Future<Duration> getTotalUsageTime(String period) async {
    final usage = await getAppUsageForPeriod(period);
    return usage.values.fold<Duration>(
      Duration.zero,
      (total, duration) => total + duration,
    );
  }

  // Get most used apps for a period
  Future<List<MapEntry<String, Duration>>> getMostUsedApps(String period, {int limit = 5}) async {
    final usage = await getAppUsageForPeriod(period);
    final sortedEntries = usage.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedEntries.take(limit).toList();
  }

  // Save app usage data (for future implementation)
  Future<void> saveAppUsageData(String packageName, Duration duration) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final key = 'app_usage_${today}_$packageName';
    
    // Convert duration to minutes for storage
    final minutes = duration.inMinutes;
    await prefs.setInt(key, minutes);
  }

  // Load app usage data (for future implementation)
  Future<Duration?> loadAppUsageData(String packageName, String date) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'app_usage_${date}_$packageName';
    final minutes = prefs.getInt(key);
    
    if (minutes != null) {
      return Duration(minutes: minutes);
    }
    return null;
  }
} 