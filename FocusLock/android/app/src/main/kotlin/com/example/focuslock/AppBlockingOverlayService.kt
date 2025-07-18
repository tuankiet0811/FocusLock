package com.example.focuslock

import android.app.Service
import android.content.Intent
import android.graphics.PixelFormat
import android.os.IBinder
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView
import android.app.ActivityManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.widget.Toast

class AppBlockingOverlayService : Service() {
    
    private lateinit var windowManager: WindowManager
    private lateinit var overlayView: View
    private lateinit var activityManager: ActivityManager
    private lateinit var usageStatsManager: UsageStatsManager
    private val handler = Handler(Looper.getMainLooper())
    private val checkRunnable = object : Runnable {
        override fun run() {
            checkCurrentApp()
            handler.postDelayed(this, 200) // Check every 200ms for faster response
        }
    }
    
    private var isOverlayShown = false
    
    companion object {
        private var blockedApps = mutableSetOf<String>()
        private var isActive = false
        
        fun setBlockedApps(apps: List<String>) {
            blockedApps.clear()
            blockedApps.addAll(apps)
            println("AppBlockingOverlayService: Set blocked apps: ${apps.joinToString(", ")}")
        }
        
        fun setActive(active: Boolean) {
            isActive = active
            println("AppBlockingOverlayService: Set active: $active")
        }
    }
    
    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (isActive) {
            startOverlay()
        }
        return START_STICKY
    }
    
    private fun startOverlay() {
        // Không add overlay ngay khi start service nữa
        startAppChecking()
        println("AppBlockingOverlayService: App checking started")
    }
    
    private fun startAppChecking() {
        handler.post(checkRunnable)
    }
    
    private val launcherPackages = setOf(
        "com.android.launcher",
        "com.google.android.apps.nexuslauncher",
        "com.miui.home",
        "com.sec.android.app.launcher",
        "com.huawei.android.launcher",
        "com.oppo.launcher",
        "com.vivo.launcher",
        "com.oneplus.launcher",
        "com.lenovo.launcher",
        "com.sonyericsson.home",
        "com.lge.launcher2"
    )
    
    private fun checkCurrentApp() {
        if (!isActive) {
            removeOverlayIfNeeded()
            return
        }
        try {
            val currentAppUsage = getCurrentAppFromUsageStats()
            val currentAppTasks = getCurrentAppFromTasks()
            println("AppBlockingOverlayService: UsageStats foreground: $currentAppUsage, Tasks foreground: $currentAppTasks, Blocked: ${blockedApps.joinToString()}")
            val currentApp = currentAppUsage ?: currentAppTasks
            if (currentApp != null && blockedApps.contains(currentApp) && !launcherPackages.contains(currentApp)) {
                showOverlayIfNeeded()
            } else {
                removeOverlayIfNeeded()
            }
        } catch (e: SecurityException) {
            println("AppBlockingOverlayService: Permission denied: ${e.message}")
        } catch (e: Exception) {
            println("AppBlockingOverlayService: Error checking app: ${e.message}")
        }
    }
    
    private fun getCurrentAppFromUsageStats(): String? {
        try {
            val currentTime = System.currentTimeMillis()
            val stats = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY,
                currentTime - 1000 * 60 * 60 * 24, // Last 24 hours
                currentTime
            )
            
            // Find the most recently used app
            var mostRecentApp: String? = null
            var mostRecentTime = 0L
            
            for (stat in stats) {
                if (stat.lastTimeUsed > mostRecentTime) {
                    mostRecentTime = stat.lastTimeUsed
                    mostRecentApp = stat.packageName
                }
            }
            
            return mostRecentApp
        } catch (e: Exception) {
            println("AppBlockingOverlayService: Error getting app from UsageStats: ${e.message}")
            return null
        }
    }
    
    private fun getCurrentAppFromTasks(): String? {
        try {
            val tasks = activityManager.getRunningTasks(1)
            if (tasks.isNotEmpty()) {
                return tasks[0].topActivity?.packageName
            }
        } catch (e: SecurityException) {
            println("AppBlockingOverlayService: Permission denied for getRunningTasks: ${e.message}")
        } catch (e: Exception) {
            println("AppBlockingOverlayService: Error getting app from Tasks: ${e.message}")
        }
        return null
    }
    
    private fun handleBlockedApp(packageName: String) {
        println("AppBlockingOverlayService: Handling blocked app: $packageName")
        // XÓA đoạn code đẩy về home, chỉ giữ lại overlay và toast nếu có
        // (Không còn startActivity(homeIntent))
        // Show blocking dialog
        showOverlayIfNeeded()
        // Show toast
        Toast.makeText(
            this,
            "Ứng dụng này đã bị chặn trong thời gian tập trung",
            Toast.LENGTH_SHORT
        ).show()
    }
    
    private fun showOverlayIfNeeded() {
        if (isOverlayShown) return
        try {
            overlayView = LayoutInflater.from(this).inflate(R.layout.blocking_overlay, null)
            val params = WindowManager.LayoutParams(
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
                0, // Không flag nào, chặn triệt để mọi thao tác
                PixelFormat.TRANSLUCENT
            )
            params.gravity = Gravity.TOP or Gravity.START
            windowManager.addView(overlayView, params)
            isOverlayShown = true
            println("AppBlockingOverlayService: Overlay shown")
        } catch (e: Exception) {
            println("AppBlockingOverlayService: Failed to add overlay: ${e.message}")
        }
    }

    private fun removeOverlayIfNeeded() {
        if (!isOverlayShown) return
        try {
            if (::overlayView.isInitialized) {
                windowManager.removeView(overlayView)
            }
            isOverlayShown = false
            println("AppBlockingOverlayService: Overlay removed")
        } catch (e: Exception) {
            println("AppBlockingOverlayService: Failed to remove overlay: ${e.message}")
        }
    }
    
    override fun onDestroy() {
        super.onDestroy()
        handler.removeCallbacks(checkRunnable)
        removeOverlayIfNeeded()
    }
    
    override fun onBind(intent: Intent?): IBinder? = null
} 