package com.example.focuslock

import android.app.ActivityManager
import android.app.AlertDialog
import android.app.NotificationManager // Thêm dòng này
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build // Thêm dòng này
import android.provider.Settings
import android.view.WindowManager
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.Calendar

class AppBlockingPlugin : FlutterPlugin, MethodCallHandler {
  private lateinit var channel : MethodChannel
  private lateinit var context: Context
  private lateinit var activityManager: ActivityManager
  private lateinit var packageManager: PackageManager
  
  private var blockedApps = mutableSetOf<String>()
  private var isBlockingActive = false

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "focuslock/app_blocking")
    channel.setMethodCallHandler(this)
    context = flutterPluginBinding.applicationContext
    activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
    packageManager = context.packageManager
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "init" -> {
        result.success(null)
      }
      "startBlocking" -> {
        val apps = call.argument<List<String>>("blockedApps") ?: emptyList()
        startBlocking(apps)
        result.success(null)
      }
      "stopBlocking" -> {
        stopBlocking()
        result.success(null)
      }
      "getCurrentApp" -> {
        val currentApp = getCurrentApp()
        result.success(currentApp)
      }
      "showBlockedAppDialog" -> {
        val appName = call.argument<String>("appName") ?: "Unknown App"
        val packageName = call.argument<String>("packageName") ?: ""
        showBlockedAppDialog(appName, packageName)
        result.success(null)
      }
      "requestPermissions" -> {
        val hasPermissions = requestPermissions()
        result.success(hasPermissions)
      }
      "requestAccessibilityPermission" -> {
        val hasAccessibility = requestAccessibilityPermission()
        result.success(hasAccessibility)
      }
      "checkPermissions" -> {
        val hasPermissions = checkPermissions()
        result.success(hasPermissions)
      }
      "checkUsageAccessPermission" -> {
        val hasUsageAccess = checkUsageAccessPermission()
        result.success(hasUsageAccess)
      }
      "checkOverlayPermission" -> {
        val hasOverlay = checkOverlayPermission()
        result.success(hasOverlay)
      }
      "checkAccessibilityPermission" -> {
        val hasAccessibility = checkAccessibilityPermission()
        result.success(hasAccessibility)
      }
      "getInstalledApps" -> {
        val apps = getInstalledApps()
        result.success(apps)
      }
      "debugCurrentApp" -> {
        val debugInfo = debugCurrentApp()
        result.success(debugInfo)
      }
      "getAppUsageStats" -> {
        getAppUsageStats(call, result)
      }
      "checkNotificationPermission" -> {
        checkNotificationPermission(result)
      }
      "requestUsageAccessPermission" -> {
        try {
          val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
          intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
          context.startActivity(intent)
          result.success(true)
        } catch (e: Exception) {
          result.error("USAGE_ACCESS_ERROR", e.message, null)
        }
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  private fun startBlocking(apps: List<String>) {
    blockedApps.clear()
    blockedApps.addAll(apps)
    isBlockingActive = true
    
    // Start overlay service (primary method)
    AppBlockingOverlayService.setBlockedApps(apps)
    AppBlockingOverlayService.setActive(true)
    
    val overlayIntent = Intent(context, AppBlockingOverlayService::class.java)
    context.startService(overlayIntent)
    
    // Start accessibility service (backup method)
    FocusLockAccessibilityService.setBlockedApps(apps)
    FocusLockAccessibilityService.setBlockingActive(true)
    
    println("AppBlockingPlugin: Started blocking ${apps.size} apps: ${apps.joinToString(", ")}")
  }

  private fun stopBlocking() {
    isBlockingActive = false
    blockedApps.clear()
    
    // Stop overlay service
    AppBlockingOverlayService.setActive(false)
    val overlayIntent = Intent(context, AppBlockingOverlayService::class.java)
    context.stopService(overlayIntent)
    
    // Stop accessibility service
    FocusLockAccessibilityService.setBlockingActive(false)
}

  private fun getCurrentApp(): String? {
    try {
      val tasks = activityManager.getRunningTasks(1)
      if (tasks.isNotEmpty()) {
        val topActivity = tasks[0].topActivity
        val packageName = topActivity?.packageName
        println("AppBlockingPlugin: Current app detected: $packageName")
        return packageName
      }
    } catch (e: SecurityException) {
      println("AppBlockingPlugin: Permission denied for getRunningTasks: ${e.message}")
    } catch (e: Exception) {
      println("AppBlockingPlugin: Error getting current app: ${e.message}")
    }
    return null
  }

  private fun showBlockedAppDialog(appName: String, packageName: String) {
    try {
      val dialog = AlertDialog.Builder(context)
        .setTitle("Ứng dụng bị chặn")
        .setMessage("Bạn đang trong thời gian tập trung. $appName đã bị chặn để giúp bạn tập trung vào công việc.")
        .setPositiveButton("Quay lại FocusLock") { _, _ ->
          // Launch FocusLock app
          val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
          intent?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
          context.startActivity(intent)
        }
        .setNegativeButton("Dừng phiên tập trung") { _, _ ->
          // Stop focus session
          channel.invokeMethod("stopFocusSession", null)
        }
        .setCancelable(false)
        .create()

      dialog.window?.addFlags(WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED)
      dialog.window?.addFlags(WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD)
      dialog.window?.addFlags(WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON)
      dialog.show()
    } catch (e: Exception) {
      // Handle dialog creation error
    }
  }

  private fun requestPermissions(): Boolean {
    try {
        // Mở trang "Hiển thị trên ứng dụng khác" (overlay)
        val overlayIntent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
            Uri.parse("package:" + context.packageName))
        overlayIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(overlayIntent)
        return true
    } catch (e: Exception) {
        println("AppBlockingPlugin: Failed to open overlay permission: ${e.message}")
        // Fallback: Thử mở MIUI-specific settings nếu là máy Xiaomi
        try {
            val miuiIntent = Intent("miui.intent.action.APP_PERM_EDITOR")
            miuiIntent.setClassName("com.miui.securitycenter", "com.miui.permcenter.permissions.PermissionsEditorActivity")
            miuiIntent.putExtra("extra_pkgname", context.packageName)
            miuiIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(miuiIntent)
            return true
        } catch (ex: Exception) {
            println("AppBlockingPlugin: Failed to open MIUI overlay permission: ${ex.message}")
            return false
        }
    }
}

  private fun requestAccessibilityPermission(): Boolean {
    try {
      // Try to open accessibility settings
      val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
      intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
      context.startActivity(intent)
      
      // Also try to open MIUI-specific settings
      try {
        val miuiIntent = Intent("miui.intent.action.extra_accessibility_settings")
        miuiIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(miuiIntent)
      } catch (e: Exception) {
        // MIUI-specific intent not available
      }
      
      return true
    } catch (e: Exception) {
      println("AppBlockingPlugin: Failed to open accessibility settings: ${e.message}")
      return false
    }
  }

  private fun checkPermissions(): Boolean {
    // For app blocking, we need usage stats permission
    return try {
      val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as android.app.usage.UsageStatsManager
      val currentTime = System.currentTimeMillis()
      val stats = usageStatsManager.queryUsageStats(
        android.app.usage.UsageStatsManager.INTERVAL_DAILY,
        currentTime - 1000 * 60 * 60 * 24,
        currentTime
      )
      val hasUsageAccess = stats.isNotEmpty()
      
      // Also check if we can get running tasks
      val canGetTasks = try {
        val tasks = activityManager.getRunningTasks(1)
        tasks.isNotEmpty()
      } catch (e: SecurityException) {
        false
      }
      
      println("AppBlockingPlugin: Usage access: $hasUsageAccess, Can get tasks: $canGetTasks")
      hasUsageAccess || canGetTasks
    } catch (e: SecurityException) {
      println("AppBlockingPlugin: No usage access permission")
      false
    }
  }

  private fun getInstalledApps(): List<Map<String, Any>> {
    println("AppBlockingPlugin: Đã gọi getInstalledApps")
    val apps = mutableListOf<Map<String, Any>>()
    val popularSystemApps = setOf(
        "com.google.android.youtube",
        "com.facebook.katana",
        "com.facebook.orca",
        "com.instagram.android",
        "com.whatsapp",
        "com.zing.zalo",
        "com.google.android.apps.messaging"
        // Thêm các package phổ biến khác nếu muốn
    )
    try {
      val installedApps = packageManager.getInstalledApplications(PackageManager.GET_META_DATA)
      for (appInfo in installedApps) {
        // Lấy app user hoặc app hệ thống phổ biến, loại trừ app chính FocusLock
        if (
          (appInfo.packageName != context.packageName) &&
          (
            (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) == 0 ||
            popularSystemApps.contains(appInfo.packageName)
          )
        ) {
          val appName = try {
            packageManager.getApplicationLabel(appInfo).toString()
          } catch (e: Exception) {
            appInfo.packageName
          }
          
          // Lấy category từ hệ thống (Android 8.0+)
          val category = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            when (appInfo.category) {
              ApplicationInfo.CATEGORY_GAME -> "gaming"
              ApplicationInfo.CATEGORY_SOCIAL -> "social"
              ApplicationInfo.CATEGORY_AUDIO -> "entertainment"
              ApplicationInfo.CATEGORY_VIDEO -> "entertainment"
              ApplicationInfo.CATEGORY_PRODUCTIVITY -> "productivity"
              ApplicationInfo.CATEGORY_NEWS -> "news"
              ApplicationInfo.CATEGORY_MAPS -> "utilities"
              ApplicationInfo.CATEGORY_IMAGE -> "utilities"
              else -> "other"
            }
          } else {
            "other" // Fallback cho Android cũ hơn
          }
          
          apps.add(mapOf(
            "packageName" to appInfo.packageName,
            "appName" to appName,
            "isBlocked" to blockedApps.contains(appInfo.packageName),
            "category" to category
          ))
        }
      }
      println("AppBlockingPlugin: Số lượng app lấy được (user + system phổ biến): ${apps.size}")
    } catch (e: Exception) {
      println("AppBlockingPlugin: Lỗi khi lấy danh sách app: ${e.message}")
      e.printStackTrace()
    }
    return apps
  }

  private fun debugCurrentApp(): Map<String, Any?> {
    val currentApp = getCurrentApp()
    return mapOf(
      "currentApp" to currentApp,
      "isBlockingActive" to isBlockingActive,
      "blockedApps" to blockedApps.toList()
    )
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  private fun checkUsageAccessPermission(): Boolean {
    return try {
      val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as android.app.usage.UsageStatsManager
      val currentTime = System.currentTimeMillis()
      val stats = usageStatsManager.queryUsageStats(
        android.app.usage.UsageStatsManager.INTERVAL_DAILY,
        currentTime - 1000 * 60 * 60 * 24,
        currentTime
      )
      stats.isNotEmpty()
    } catch (e: Exception) {
      false
    }
  }

  private fun checkOverlayPermission(): Boolean {
    return try {
      Settings.canDrawOverlays(context)
    } catch (e: Exception) {
      false
    }
  }

  private fun checkAccessibilityPermission(): Boolean {
    try {
      val enabledServices = Settings.Secure.getString(context.contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES)
      val colonSplitter = enabledServices?.split(":") ?: return false
      for (service in colonSplitter) {
        if (service.contains(context.packageName, ignoreCase = true)) {
          return true
        }
      }
      return false
    } catch (e: Exception) {
      return false
    }
  }

  private fun getAppUsageStats(call: MethodCall, result: Result) {
      val period = call.argument<String>("period") ?: "today"
      val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
      
      val calendar = Calendar.getInstance()
      val endTime = calendar.timeInMillis
      
      val startTime = when (period) {
          "today" -> {
              calendar.set(Calendar.HOUR_OF_DAY, 0)
              calendar.set(Calendar.MINUTE, 0)
              calendar.set(Calendar.SECOND, 0)
              calendar.set(Calendar.MILLISECOND, 0)
              calendar.timeInMillis
          }
          "week" -> {
              calendar.add(Calendar.DAY_OF_YEAR, -7)
              calendar.timeInMillis
          }
          "month" -> {
              calendar.add(Calendar.MONTH, -1)
              calendar.timeInMillis
          }
          else -> endTime - (24 * 60 * 60 * 1000) // Default to today
      }
      
      try {
          val usageStats = usageStatsManager.queryUsageStats(
              UsageStatsManager.INTERVAL_DAILY,
              startTime,
              endTime
          )
          
          val usageMap = mutableMapOf<String, Long>()
          
          for (usageStat in usageStats) {
              val packageName = usageStat.packageName
              val totalTime = usageStat.totalTimeInForeground
              
              if (totalTime > 0) {
                  // Lấy tên app thực tế
                  val appName = getAppName(packageName) ?: packageName
                  usageMap[appName] = totalTime
              }
          }
          
          result.success(usageMap)
      } catch (e: Exception) {
          result.error("USAGE_STATS_ERROR", "Failed to get usage stats: ${e.message}", null)
      }
  }

  private fun getAppName(packageName: String): String? {
      return try {
          val applicationInfo = packageManager.getApplicationInfo(packageName, 0)
          packageManager.getApplicationLabel(applicationInfo).toString()
      } catch (e: Exception) {
          null
      }
  }
  
  private fun checkNotificationPermission(result: MethodChannel.Result) {
      try {
          val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
          val areEnabled = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
              notificationManager.areNotificationsEnabled()
          } else {
              true // Trước Android N, không có API để kiểm tra
          }
          result.success(areEnabled)
      } catch (e: Exception) {
          result.error("PERMISSION_ERROR", "Failed to check notification permission", e.message)
      }
  }
}