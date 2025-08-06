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
            handler.postDelayed(this, 50) // Giảm từ 200ms xuống 50ms để phản hồi nhanh hơn
        }
    }
    
    private var isOverlayShown = false
    private var isTemporarilyDisabled = false
    private val tempDisableHandler = Handler(Looper.getMainLooper())
    
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
        
        // Kiểm tra ngay lập tức khi có thay đổi
        if (isTemporarilyDisabled) {
            removeOverlayIfNeeded()
            return
        }
        
        try {
            val currentAppUsage = getCurrentAppFromUsageStats()
            val currentAppTasks = getCurrentAppFromTasks()
            println("AppBlockingOverlayService: UsageStats foreground: $currentAppUsage, Tasks foreground: $currentAppTasks, Blocked: ${blockedApps.joinToString()}")
            val currentApp = currentAppUsage ?: currentAppTasks
            
            if (currentApp != null && blockedApps.contains(currentApp) && !launcherPackages.contains(currentApp)) {
                // Hiển thị overlay ngay lập tức
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
            return null
        }
    }
    
    private fun getCurrentAppFromTasks(): String? {
        try {
            val tasks = activityManager.getRunningTasks(1)
            if (tasks.isNotEmpty()) {
                return tasks[0].topActivity?.packageName
            }
        } catch (e: Exception) {
            // Fallback or handle exception
        }
        return null
    }
    
    private fun handleBlockedApp(packageName: String) {
        showOverlayIfNeeded()
        
        // Show toast message
        Toast.makeText(this, "App $packageName đã bị chặn bởi FocusLock", Toast.LENGTH_SHORT).show()
    }
    
    private fun showOverlayIfNeeded() {
        if (isOverlayShown || isTemporarilyDisabled) return
        try {
            overlayView = LayoutInflater.from(this).inflate(R.layout.blocking_overlay, null)
            
            // Thêm xử lý nút Quay lại
            val btnGoBack = overlayView.findViewById<Button>(R.id.btnGoBack)
            btnGoBack?.setOnClickListener {
                // Ẩn overlay
                removeOverlayIfNeeded()
                
                // Tạm dừng overlay trong 3 giây để user có thể chuyển app
                isTemporarilyDisabled = true
                tempDisableHandler.postDelayed({
                    isTemporarilyDisabled = false
                }, 3000) // 3 giây
                
                // Đưa người dùng về màn hình chính
                val homeIntent = Intent(Intent.ACTION_MAIN)
                homeIntent.addCategory(Intent.CATEGORY_HOME)
                homeIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                startActivity(homeIntent)
            }
            
            val params = WindowManager.LayoutParams(
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL,
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
        if (isOverlayShown) {
            try {
                windowManager.removeView(overlayView)
                isOverlayShown = false
                println("AppBlockingOverlayService: Overlay removed")
            } catch (e: Exception) {
                println("AppBlockingOverlayService: Failed to remove overlay: ${e.message}")
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        handler.removeCallbacks(checkRunnable)
        tempDisableHandler.removeCallbacksAndMessages(null)
        removeOverlayIfNeeded()
        println("AppBlockingOverlayService: Service destroyed")
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }
}