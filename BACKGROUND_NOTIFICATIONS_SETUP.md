# 🔔 Background Notifications Setup Guide

## The Problem
You're only getting notifications when the app is **open** because:
- ✅ **Realtime subscriptions** work when app is active
- ❌ **FCM push notifications** aren't being sent from your web app
- ❌ **Background notifications** aren't configured properly

## The Solution

### 1. 🌐 **Web App Integration**

Your **web app** needs to call the notification service when creating reports. Add this to your web app's report submission:

```javascript
// In your web app (after creating a report)
async function submitReport(reportData) {
  try {
    // 1. Create the report in database
    const report = await supabase
      .from('reports')
      .insert(reportData)
      .select()
      .single();
    
    // 2. Send notification to supervisor
    await supabase.functions.invoke('create_notification', {
      body: {
        supervisorId: reportData.supervisor_id,
        reportId: report.id,
        schoolName: reportData.school_name,
        reportType: 'report', // or 'maintenance'
        priority: reportData.priority,
        description: reportData.description
      }
    });
    
    console.log('✅ Report submitted and notification sent');
  } catch (error) {
    console.error('❌ Error:', error);
  }
}
```

### 2. 🔧 **Supabase Edge Function**

Create a new Edge Function: `supabase/functions/create_notification/index.ts`

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  try {
    const { 
      supervisorId, 
      reportId, 
      schoolName, 
      reportType, 
      priority, 
      description 
    } = await req.json()

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Determine notification details
    const isEmergency = priority?.toLowerCase() === 'high' || 
                       priority?.toLowerCase() === 'emergency'
    
    let title, body, notificationType
    
    if (reportType === 'maintenance') {
      title = '🔧 بلاغ صيانة جديد'
      body = `لديك طلب صيانة جديد في مدرسة ${schoolName} .. الأولوية ${priority}`
      notificationType = 'maintenance'
    } else {
      title = isEmergency ? '🚨 بلاغ عاجل' : '📋 بلاغ جديد'
      body = `لديك بلاغ جديد في مدرسة ${schoolName} .. الأولوية ${priority}`
      notificationType = isEmergency ? 'emergency' : 'new_report'
    }

    // 1. Add to notification queue
    const notificationData = {
      user_id: supervisorId,
      notification_type: notificationType,
      title: title,
      body: body,
      data: {
        type: notificationType,
        report_id: reportId,
        school_name: schoolName,
        priority: priority,
        description: description,
        is_emergency: isEmergency.toString()
      },
      processed: false
    }

    const { data: notification } = await supabase
      .from('notification_queue')
      .insert(notificationData)
      .select()
      .single()

    // 2. Send FCM notification immediately
    const fcmResponse = await supabase.functions.invoke('send_notification', {
      body: {
        user_id: supervisorId,
        title: title,
        body: body,
        data: notificationData.data,
        priority: priority || 'normal',
        school_name: schoolName
      }
    })

    if (fcmResponse.status === 200) {
      // Mark as processed
      await supabase
        .from('notification_queue')
        .update({ processed: true })
        .eq('id', notification.id)
    }

    return new Response(
      JSON.stringify({ 
        success: true, 
        notificationId: notification.id,
        fcmSent: fcmResponse.status === 200
      }),
      { headers: { "Content-Type": "application/json" } }
    )

  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 400, headers: { "Content-Type": "application/json" } }
    )
  }
})
```

### 3. 📱 **App Configuration**

#### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<application
    android:name=".MainApplication"
    android:exported="true"
    android:label="supervisor_wo"
    android:icon="@mipmap/ic_launcher">
    
    <!-- Add these permissions -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.WAKE_LOCK" />
    <uses-permission android:name="android.permission.VIBRATE" />
    
    <!-- Firebase Cloud Messaging -->
    <service
        android:name="io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingService"
        android:exported="false">
        <intent-filter>
            <action android:name="com.google.firebase.MESSAGING_EVENT" />
        </intent-filter>
    </service>
</application>
```

### 4. 🧪 **Testing the Setup**

#### Test FCM Token:
```dart
// Add this to your test button
FloatingActionButton(
  onPressed: () async {
    // Test FCM token
    final token = FCMService.instance.fcmToken;
    print('🔑 FCM Token: $token');
    
    // Test notification creation
    await NotificationService.createAndSendNotification(
      supervisorId: 'your-user-id',
      reportId: 'test-report-123',
      schoolName: 'مدرسة الاختبار',
      reportType: 'report',
      priority: 'high',
      description: 'اختبار النظام',
    );
  },
  child: Icon(Icons.notification_add),
)
```

## 🎯 **How It Works**

1. **Web App** submits report → Calls `create_notification` function
2. **Edge Function** creates notification → Calls `send_notification` function
3. **FCM Service** sends push notification → Shows on device even when app is closed
4. **User taps notification** → App opens and shows the report

## 🔍 **Debugging Steps**

1. **Check FCM Token**: Run the test and copy the FCM token
2. **Test with Firebase Console**: Send test message to the token
3. **Check Edge Function Logs**: Look for errors in Supabase dashboard
4. **Verify Database**: Check `notification_queue` and `user_fcm_tokens` tables

## ✅ **Expected Results**

- ✅ **App Open**: Instant realtime notifications
- ✅ **App Background**: Push notifications appear in system tray
- ✅ **App Closed**: Push notifications wake up the device
- ✅ **Tap Notification**: Opens app and navigates to relevant report

This setup ensures you get notifications **everywhere** - whether the app is open, backgrounded, or completely closed! 🚀 