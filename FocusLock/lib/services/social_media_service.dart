import '../models/app_info.dart';

class SocialMediaService {
  static final SocialMediaService _instance = SocialMediaService._internal();
  factory SocialMediaService() => _instance;
  SocialMediaService._internal();

  // Common social media app package names
  static const Map<String, String> socialMediaApps = {
    // Facebook family
    'com.facebook.katana': 'Facebook',
    'com.facebook.orca': 'Facebook Messenger',
    'com.instagram.android': 'Instagram',
    'com.whatsapp': 'WhatsApp',
    
    // Google services
    'com.google.android.youtube': 'YouTube',
    'com.google.android.apps.messaging': 'Google Messages',
    'com.google.android.gm': 'Gmail',
    
    // Twitter/X
    'com.twitter.android': 'Twitter/X',
    'com.x.android': 'X (Twitter)',
    
    // TikTok
    'com.zhiliaoapp.musically': 'TikTok',
    'com.ss.android.ugc.tiktok': 'TikTok (Alternative)',
    
    // Snapchat
    'com.snapchat.android': 'Snapchat',
    
    // LinkedIn
    'com.linkedin.android': 'LinkedIn',
    
    // Reddit
    'com.reddit.frontpage': 'Reddit',
    'com.reddit.launch': 'Reddit (Alternative)',
    
    // Discord
    'com.discord': 'Discord',
    
    // Telegram
    'org.telegram.messenger': 'Telegram',
    'org.telegram.plus': 'Telegram Plus',
    
    // WeChat
    'com.tencent.mm': 'WeChat',
    
    // QQ
    'com.tencent.mobileqq': 'QQ',
    
    // Line
    'jp.naver.line.android': 'Line',
    
    // Viber
    'com.viber.voip': 'Viber',
    
    // Pinterest
    'com.pinterest': 'Pinterest',
    
    // Tumblr
    'com.tumblr': 'Tumblr',
    
    // Twitch
    'tv.twitch.android.app': 'Twitch',
    
    // Medium
    'com.medium.reader': 'Medium',
    
    // Quora
    'com.quora.android': 'Quora',
    
    // Clubhouse
    'com.clubhouse.app': 'Clubhouse',
    
    // Signal
    'org.thoughtcrime.securesms': 'Signal',
    
    // Threads
    'com.instagram.threadsapp': 'Threads',
    
    // BeReal
    'com.bereal.ft': 'BeReal',
    
    // Mastodon
    'org.joinmastodon.android': 'Mastodon',
    
    // Bluesky
    'com.bluesky.social': 'Bluesky',
  };

  // Get all social media apps as AppInfo objects
  List<AppInfo> getSocialMediaApps() {
    return socialMediaApps.entries.map((entry) => AppInfo(
      packageName: entry.key,
      appName: entry.value,
      isBlocked: false,
    )).toList();
  }

  // Check if an app is a social media app
  bool isSocialMediaApp(String packageName) {
    return socialMediaApps.containsKey(packageName);
  }

  // Get social media app name
  String? getSocialMediaAppName(String packageName) {
    return socialMediaApps[packageName];
  }

  // Get popular social media apps (most commonly used)
  List<AppInfo> getPopularSocialMediaApps() {
    const popularPackages = [
      'com.facebook.katana',      // Facebook
      'com.instagram.android',    // Instagram
      'com.whatsapp',             // WhatsApp
      'com.google.android.youtube', // YouTube
      'com.twitter.android',      // Twitter/X
      'com.zhiliaoapp.musically', // TikTok
      'com.snapchat.android',     // Snapchat
      'com.discord',              // Discord
      'org.telegram.messenger',   // Telegram
    ];

    return popularPackages.map((packageName) => AppInfo(
      packageName: packageName,
      appName: socialMediaApps[packageName] ?? packageName,
      isBlocked: false,
    )).toList();
  }

  // Get messaging apps only
  List<AppInfo> getMessagingApps() {
    const messagingPackages = [
      'com.facebook.orca',        // Facebook Messenger
      'com.whatsapp',             // WhatsApp
      'com.google.android.apps.messaging', // Google Messages
      'org.telegram.messenger',   // Telegram
      'com.viber.voip',           // Viber
      'jp.naver.line.android',    // Line
      'org.thoughtcrime.securesms', // Signal
    ];

    return messagingPackages.map((packageName) => AppInfo(
      packageName: packageName,
      appName: socialMediaApps[packageName] ?? packageName,
      isBlocked: false,
    )).toList();
  }

  // Get video/entertainment apps
  List<AppInfo> getVideoEntertainmentApps() {
    const videoPackages = [
      'com.google.android.youtube', // YouTube
      'com.zhiliaoapp.musically', // TikTok
      'com.snapchat.android',     // Snapchat
      'tv.twitch.android.app',    // Twitch
    ];

    return videoPackages.map((packageName) => AppInfo(
      packageName: packageName,
      appName: socialMediaApps[packageName] ?? packageName,
      isBlocked: false,
    )).toList();
  }
} 