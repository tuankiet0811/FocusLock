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
        // Create overlay view
        overlayView = LayoutInflater.from(this).inflate(R.layout.blocking_overlay, null)
        
        // Set up window parameters
        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
            WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
            WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT
        )
        params.gravity = Gravity.TOP or Gravity.START
        
        // Add overlay to window
        try {
            windowManager.addView(overlayView, params)
            startAppChecking()
            println("AppBlockingOverlayService: Overlay started successfully")
        } catch (e: Exception) {
            println("AppBlockingOverlayService: Failed to add overlay: ${e.message}")
        }
    }
    
    private fun startAppChecking() {
        handler.post(checkRunnable)
    }
    
    private fun checkCurrentApp() {
        if (!isActive) return
        
        try {
            // Method 1: Try UsageStatsManager first (more reliable on newer Android)
            val currentApp = getCurrentAppFromUsageStats()
            if (currentApp != null && blockedApps.contains(currentApp)) {
                println("AppBlockingOverlayService: Blocked app detected via UsageStats: $currentApp")
                handleBlockedApp(currentApp)
                return
            }
            
            // Method 2: Fallback to getRunningTasks
            val currentAppFromTasks = getCurrentAppFromTasks()
            if (currentAppFromTasks != null && blockedApps.contains(currentAppFromTasks)) {
                println("AppBlockingOverlayService: Blocked app detected via Tasks: $currentAppFromTasks")
                handleBlockedApp(currentAppFromTasks)
                return
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
        
        // Go back to home
        val homeIntent = Intent(Intent.ACTION_MAIN)
        homeIntent.addCategory(Intent.CATEGORY_HOME)
        homeIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        startActivity(homeIntent)
        
        // Show blocking dialog
        showBlockingDialog(packageName)
        
        // Show toast
        Toast.makeText(
            this,
            "Ứng dụng này đã bị chặn trong thời gian tập trung",
            Toast.LENGTH_SHORT
        ).show()
    }
    
    private fun showBlockingDialog(packageName: String) {
        try {
            val dialogView = LayoutInflater.from(this).inflate(R.layout.blocking_dialog, null)
            
            val titleText = dialogView.findViewById<TextView>(R.id.dialog_title)
            val messageText = dialogView.findViewById<TextView>(R.id.dialog_message)
            val backButton = dialogView.findViewById<Button>(R.id.btn_back_to_focuslock)
            val stopButton = dialogView.findViewById<Button>(R.id.btn_stop_session)
            
            titleText.text = "Ứng dụng bị chặn"
            messageText.text = "Bạn đang trong thời gian tập trung. Ứng dụng này đã bị chặn để giúp bạn tập trung vào công việc."
            
            backButton.setOnClickListener {
                // Launch FocusLock (not the blocked app)
                val intent = packageManager.getLaunchIntentForPackage("com.example.focuslock")
                intent?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
            }
            
            stopButton.setOnClickListener {
                setActive(false)
                stopSelf()
            }
            
            val dialog = android.app.AlertDialog.Builder(this)
                .setView(dialogView)
                .setCancelable(false)
                .create()
            
            dialog.window?.addFlags(WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED)
            dialog.window?.addFlags(WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD)
            dialog.window?.addFlags(WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON)
            dialog.show()
            
        } catch (e: Exception) {
            println("AppBlockingOverlayService: Failed to show dialog: ${e.message}")
        }
    }
    
    override fun onDestroy() {
        super.onDestroy()
        handler.removeCallbacks(checkRunnable)
        try {
            if (::overlayView.isInitialized) {
                windowManager.removeView(overlayView)
            }
        } catch (e: Exception) {
            println("AppBlockingOverlayService: Failed to remove overlay: ${e.message}")
        }
    }
    
    override fun onBind(intent: Intent?): IBinder? = null
} 