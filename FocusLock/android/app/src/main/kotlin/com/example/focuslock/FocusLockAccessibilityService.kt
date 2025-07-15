package com.example.focuslock

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.app.AlertDialog
import android.content.Intent
import android.view.WindowManager
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.widget.Toast

class FocusLockAccessibilityService : AccessibilityService() {
    
    companion object {
        private var blockedApps = mutableSetOf<String>()
        private var isBlockingActive = false
        
        fun setBlockedApps(apps: List<String>) {
            blockedApps.clear()
            blockedApps.addAll(apps)
            println("FocusLockAccessibilityService: Set blocked apps: ${apps.joinToString(", ")}")
        }
        
        fun setBlockingActive(active: Boolean) {
            isBlockingActive = active
            println("FocusLockAccessibilityService: Set blocking active: $active")
        }
    }
    
    override fun onServiceConnected() {
        super.onServiceConnected()
        
        val info = AccessibilityServiceInfo()
        info.apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED or 
                        AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED or
                        AccessibilityEvent.TYPE_VIEW_CLICKED or
                        AccessibilityEvent.TYPE_VIEW_FOCUSED or
                        AccessibilityEvent.TYPE_VIEW_ACCESSIBILITY_FOCUSED or
                        AccessibilityEvent.TYPE_WINDOWS_CHANGED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            flags = AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS or
                   AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS or
                   AccessibilityServiceInfo.FLAG_REQUEST_FILTER_KEY_EVENTS
            notificationTimeout = 50 // Faster response
        }
        
        serviceInfo = info
        println("FocusLockAccessibilityService: Service connected and configured")
    }
    
    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        if (!isBlockingActive) return
        
        when (event.eventType) {
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED -> {
                val packageName = event.packageName?.toString()
                if (packageName != null && blockedApps.contains(packageName)) {
                    println("FocusLockAccessibilityService: Blocked app detected via WINDOW_STATE_CHANGED: $packageName")
                    handleBlockedApp(packageName)
                }
            }
            AccessibilityEvent.TYPE_WINDOWS_CHANGED -> {
                val packageName = event.packageName?.toString()
                if (packageName != null && blockedApps.contains(packageName)) {
                    println("FocusLockAccessibilityService: Blocked app detected via WINDOWS_CHANGED: $packageName")
                    handleBlockedApp(packageName)
                }
            }
            AccessibilityEvent.TYPE_VIEW_CLICKED -> {
                // Intercept clicks on app icons or app-related elements
                val source = event.source
                if (source != null) {
                    val packageName = getPackageNameFromView(source)
                    if (packageName != null && blockedApps.contains(packageName)) {
                        println("FocusLockAccessibilityService: Blocked app detected via VIEW_CLICKED: $packageName")
                        handleBlockedApp(packageName)
                        return
                    }
                }
            }
            AccessibilityEvent.TYPE_VIEW_FOCUSED -> {
                // Check if focused element belongs to blocked app
                val source = event.source
                if (source != null) {
                    val packageName = source.packageName?.toString()
                    if (packageName != null && blockedApps.contains(packageName)) {
                        println("FocusLockAccessibilityService: Blocked app detected via VIEW_FOCUSED: $packageName")
                        handleBlockedApp(packageName)
                    }
                }
            }
        }
    }
    
    private fun getPackageNameFromView(nodeInfo: AccessibilityNodeInfo): String? {
        // Try to get package name from various sources
        var current = nodeInfo
        while (current != null) {
            val packageName = current.packageName?.toString()
            if (packageName != null && packageName != packageName && blockedApps.contains(packageName)) {
                return packageName
            }
            
            // Check if this is a clickable element that might launch an app
            if (current.isClickable) {
                val contentDescription = current.contentDescription?.toString() ?: ""
                val text = current.text?.toString() ?: ""
                
                // Check if content description or text contains app names
                for (blockedApp in blockedApps) {
                    if (contentDescription.contains(blockedApp, ignoreCase = true) || 
                        text.contains(blockedApp, ignoreCase = true)) {
                        return blockedApp
                    }
                }
            }
            
            current = current.parent
        }
        return null
    }
    
    private fun handleBlockedApp(packageName: String) {
        println("FocusLockAccessibilityService: Handling blocked app: $packageName")
        
        // Go back to home screen
        performGlobalAction(GLOBAL_ACTION_HOME)
        
        // Show blocking dialog
        showBlockingDialog(packageName)
        
        // Show toast message
        Toast.makeText(
            this,
            "Ứng dụng này đã bị chặn trong thời gian tập trung",
            Toast.LENGTH_SHORT
        ).show()
    }
    
    private fun showBlockingDialog(packageName: String) {
        try {
            val dialog = AlertDialog.Builder(this)
                .setTitle("Ứng dụng bị chặn")
                .setMessage("Bạn đang trong thời gian tập trung. Ứng dụng này đã bị chặn để giúp bạn tập trung vào công việc.")
                .setPositiveButton("Quay lại FocusLock") { _, _ ->
                    // Launch FocusLock app (not the blocked app)
                    val intent = packageManager.getLaunchIntentForPackage("com.example.focuslock")
                    intent?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                }
                .setNegativeButton("Dừng phiên tập trung") { _, _ ->
                    // Stop focus session
                    setBlockingActive(false)
                }
                .setCancelable(false)
                .create()

            dialog.window?.addFlags(WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED)
            dialog.window?.addFlags(WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD)
            dialog.window?.addFlags(WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON)
            dialog.show()
        } catch (e: Exception) {
            println("FocusLockAccessibilityService: Failed to show dialog: ${e.message}")
        }
    }
    
    override fun onInterrupt() {
        // Not used
    }
} 