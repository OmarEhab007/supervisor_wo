import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type'
};

// Get access token using service account JSON
async function getAccessToken() {
  try {
    const serviceAccountJson = Deno.env.get('FIREBASE_SERVICE_ACCOUNT');
    if (!serviceAccountJson) {
      throw new Error('FIREBASE_SERVICE_ACCOUNT not set');
    }
    console.log('🔍 Parsing service account JSON...');
    
    // Clean up the JSON string - handle different line endings and escaping
    let cleanedJson = serviceAccountJson.trim();
    if (cleanedJson.startsWith('"') && cleanedJson.endsWith('"')) {
      cleanedJson = cleanedJson.slice(1, -1);
    }
    cleanedJson = cleanedJson.replace(/\\"/g, '"').replace(/\\\\/g, '\\');
    const serviceAccount = JSON.parse(cleanedJson);
    
    console.log('🔐 Using service account:', serviceAccount.client_email);
    console.log('📋 Project ID:', serviceAccount.project_id);
    
    // Generate JWT and get access token
    const response = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      body: new URLSearchParams({
        grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        assertion: await createJWT(serviceAccount)
      })
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error('❌ Token request failed:', response.status, errorText);
      throw new Error(`Token request failed: ${response.status}`);
    }

    const tokenData = await response.json();
    console.log('✅ Access token obtained successfully');
    return tokenData.access_token;
  } catch (error) {
    console.error('❌ Error getting access token:', error);
    throw error;
  }
}

// Create JWT using Web Crypto API
async function createJWT(serviceAccount) {
  const now = Math.floor(Date.now() / 1000);
  const header = {
    alg: 'RS256',
    typ: 'JWT',
    kid: serviceAccount.private_key_id
  };

  const payload = {
    iss: serviceAccount.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    exp: now + 3600,
    iat: now
  };

  // Encode header and payload
  const encodedHeader = btoa(JSON.stringify(header)).replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');
  const encodedPayload = btoa(JSON.stringify(payload)).replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');
  const message = `${encodedHeader}.${encodedPayload}`;

  // Import private key (handle different line ending formats)
  const keyData = serviceAccount.private_key.replace(/\\n/g, '\n').replace(/\r\n/g, '\n');
  const pemContents = keyData.replace('-----BEGIN PRIVATE KEY-----', '').replace('-----END PRIVATE KEY-----', '').replace(/\s/g, '');
  const keyBuffer = Uint8Array.from(atob(pemContents), (c) => c.charCodeAt(0));

  const privateKey = await crypto.subtle.importKey(
    'pkcs8',
    keyBuffer,
    {
      name: 'RSASSA-PKCS1-v1_5',
      hash: 'SHA-256'
    },
    false,
    ['sign']
  );

  // Sign the message
  const signature = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', privateKey, new TextEncoder().encode(message));
  const encodedSignature = btoa(String.fromCharCode(...new Uint8Array(signature))).replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');

  return `${message}.${encodedSignature}`;
}

// Format Arabic notification text - updated to handle both report types
function formatNotificationText(requestData) {
  const { priority, school_name, data, title, body } = requestData;
  
  // Check if this is a maintenance report using multiple detection methods
  const isMaintenance = data?.is_maintenance === true || 
                       data?.type === 'maintenance' || 
                       data?.report_type === 'maintenance' ||
                       title?.includes('صيانة') ||
                       body?.includes('صيانة');
  
  console.log('🔧 Report type detection:', {
    isMaintenance,
    hasData: !!data,
    dataType: data?.type,
    reportType: data?.report_type,
    titleContainsMaintenance: title?.includes('صيانة'),
    bodyContainsMaintenance: body?.includes('صيانة'),
    providedTitle: title,
    providedBody: body
  });

  if (isMaintenance) {
    // Maintenance reports - simpler structure, no priority system
    const maintenanceTitle = title || '🔧 بلاغ صيانة جديد';
    const maintenanceBody = body || `لديك طلب صيانة جديد في ${school_name || 'مدرسة غير محددة'}`;
    
    return {
      title: maintenanceTitle,
      body: maintenanceBody,
      priorityArabic: 'صيانة',
      isEmergency: false,
      isMaintenance: true
    };
  } else {
    // Regular reports - with priority handling
    const isEmergency = priority?.toLowerCase() === 'emergency' || 
                       priority?.toLowerCase() === 'high' ||
                       data?.is_emergency === true ||
                       data?.is_emergency === 'true';
    
    const priorityArabic = isEmergency ? 'طارئ' : 'روتيني';
    const reportTitle = title || (isEmergency ? 'بلاغ عاجل 🚨' : 'بلاغ جديد 📋');
    
    // Better formatted body with proper spacing and structure
    const reportBody = body || [
      `المدرسة : ${school_name || 'غير محددة'}`,
      ``,
      `الأولوية : ${priorityArabic}`
    ].join('\n');

    return {
      title: reportTitle,
      body: reportBody,
      priorityArabic,
      isEmergency,
      isMaintenance: false
    };
  }
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // Debug endpoint
    const url = new URL(req.url);
    if (url.searchParams.has('debug')) {
      const serviceAccountJson = Deno.env.get('FIREBASE_SERVICE_ACCOUNT');
      console.log('Debug - Service Account Raw (first 200 chars):', serviceAccountJson?.substring(0, 200));
      return new Response(JSON.stringify({
        hasServiceAccount: !!serviceAccountJson,
        length: serviceAccountJson?.length || 0,
        firstChars: serviceAccountJson?.substring(0, 50) || 'N/A',
        projectId: Deno.env.get('FIREBASE_PROJECT_ID')
      }), {
        headers: { 'Content-Type': 'application/json' }
      });
    }

    console.log('🚀 Send notification function called');
    console.log('Method:', req.method);
    console.log('Headers:', Object.fromEntries(req.headers.entries()));

    // Better JSON parsing with error handling
    let requestData;
    try {
      const bodyText = await req.text();
      console.log('Raw body:', bodyText.substring(0, 500)); // Increased for better debugging
      
      if (!bodyText || bodyText.trim() === '') {
        throw new Error('Request body is empty');
      }
      
      requestData = JSON.parse(bodyText);
      console.log('📋 Parsed request data:', {
        user_id: requestData.user_id,
        title: requestData.title,
        body: requestData.body,
        priority: requestData.priority,
        school_name: requestData.school_name,
        data: requestData.data
      });
    } catch (parseError) {
      console.error('❌ JSON Parse Error:', parseError);
      return new Response(JSON.stringify({
        error: 'Invalid JSON in request body',
        details: parseError.message,
        example: {
          user_id: "user-id-here",
          title: "بلاغ جديد",
          body: "لديك بلاغ جديد",
          priority: "Emergency",
          school_name: "اسم المدرسة",
          data: {
            type: "new_report",
            is_maintenance: false
          }
        }
      }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    const { user_id, title, body, data, priority, school_name } = requestData;

    // Validate required fields
    if (!user_id) {
      return new Response(JSON.stringify({
        error: 'user_id is required'
      }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    console.log('📝 Request data received:', {
      user_id,
      priority: priority || 'not provided',
      school_name: school_name || 'not provided',
      hasData: !!data,
      dataKeys: data ? Object.keys(data) : []
    });

    const supabase = createClient(
      'https://cftjaukrygtzguqcafon.supabase.co',
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNmdGphdWtyeWd0emd1cWNhZm9uIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0ODMyNTU3NiwiZXhwIjoyMDYzOTAxNTc2fQ.nuFdtGZhNxYAyGABC1XcaQmy2cJouf-fudaj9zPoLKA'
    );

    // Get FCM tokens for user
    const { data: tokens, error: tokenError } = await supabase
      .from('user_fcm_tokens')
      .select('fcm_token')
      .eq('user_id', user_id);

    console.log('🔑 FCM tokens found:', tokens?.length || 0);

    if (tokenError) {
      console.error('❌ Error fetching tokens:', tokenError);
      throw tokenError;
    }

    if (!tokens || tokens.length === 0) {
      console.log('⚠️ No FCM tokens found for user:', user_id);
      return new Response(JSON.stringify({
        success: false,
        error: 'No FCM tokens found for user'
      }), {
        status: 200,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    // Get access token
    console.log('🔑 Getting access token...');
    const accessToken = await getAccessToken();

    // Format notification text with improved logic for different report types
    const { 
      title: arabicTitle, 
      body: arabicBody, 
      priorityArabic, 
      isEmergency, 
      isMaintenance 
    } = formatNotificationText(requestData);

    console.log('📧 Sending FCM notifications:', {
      title: arabicTitle,
      priority: priorityArabic,
      isEmergency,
      isMaintenance
    });

    // Get project ID from service account
    const serviceAccountJson = Deno.env.get('FIREBASE_SERVICE_ACCOUNT');
    const serviceAccount = JSON.parse(serviceAccountJson);
    const projectId = serviceAccount.project_id;

    // Send FCM notifications using v1 API
    const fcmResults = [];
    for (let i = 0; i < tokens.length; i++) {
      const tokenRow = tokens[i];
      console.log(`📤 Sending FCM notification ${i + 1}/${tokens.length}`);

      try {
        // Enhanced data payload that works for both report types
        const notificationData = {
          ...data || {},
          type: isMaintenance ? 'maintenance' : 'new_report',
          priority: priority || (isMaintenance ? 'maintenance' : 'routine'),
          priority_arabic: priorityArabic,
          school_name: school_name || 'غير محدد',
          is_emergency: isEmergency.toString(),
          is_maintenance: isMaintenance.toString(),
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
          sound: 'default'
        };

        // Fixed v1 API payload structure
        const v1Payload = {
          message: {
            token: tokenRow.fcm_token,
            notification: {
              title: arabicTitle,
              body: arabicBody
            },
            data: notificationData,
            android: {
              // Priority based on emergency status, not maintenance
              priority: isEmergency ? 'HIGH' : 'NORMAL',
              notification: {
                channel_id: isMaintenance ? 'supervisor_maintenance_channel' : 'supervisor_reports_channel',
                sound: 'default',
                click_action: 'FLUTTER_NOTIFICATION_CLICK',
                color: isMaintenance ? '#9C27B0' : (isEmergency ? '#FF0000' : '#2196F3'),
                icon: 'ic_notification',
                tag: isMaintenance ? 'supervisor_maintenance' : 'supervisor_report',
                sticky: isEmergency,
                // Different vibration patterns for different report types
                vibrate_timings: isEmergency ? ['0.5s', '0.2s', '0.5s'] : 
                                isMaintenance ? ['0.3s', '0.1s', '0.3s'] : ['0.2s'],
                visibility: 'PUBLIC'
              },
              data: {
                click_action: 'FLUTTER_NOTIFICATION_CLICK'
              }
            },
            apns: {
              payload: {
                aps: {
                  sound: 'default',
                  badge: 1,
                  alert: {
                    title: arabicTitle,
                    body: arabicBody
                  },
                  category: isMaintenance ? 'SUPERVISOR_MAINTENANCE' : 'SUPERVISOR_REPORT',
                  'thread-id': isMaintenance ? 'supervisor-maintenance' : 'supervisor-reports'
                }
              }
            }
          }
        };

        console.log('📨 Sending FCM notification with payload for:', isMaintenance ? 'maintenance' : 'regular report');

        // Send to FCM v1 API
        const response = await fetch(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${accessToken}`,
            'Content-Type': 'application/json'
          },
          body: JSON.stringify(v1Payload)
        });

        const result = await response.json();

        // Enhanced logging for debugging
        console.log(`📊 FCM Response ${i + 1} Details:`, {
          status: response.status,
          success: response.ok,
          messageId: result.name || 'unknown'
        });

        if (!response.ok) {
          console.error(`❌ FCM Error Details:`, {
            status: response.status,
            error: result.error,
            message: result.error?.message
          });
        } else {
          console.log(`✅ FCM notification sent successfully: ${result.name}`);
        }

        fcmResults.push({
          token: tokenRow.fcm_token.substring(0, 20) + '...',
          status: response.status,
          success: response.ok,
          messageId: result.name || null,
          error: result.error || null
        });
      } catch (fcmError) {
        console.error(`❌ FCM Error for token ${i + 1}:`, fcmError);
        fcmResults.push({
          token: tokenRow.fcm_token.substring(0, 20) + '...',
          status: 'error',
          success: false,
          error: fcmError.message
        });
      }
    }

    console.log('🎉 All FCM notifications processed');

    return new Response(JSON.stringify({
      success: true,
      message: 'FCM notifications sent successfully',
      api: 'v1',
      reportType: isMaintenance ? 'maintenance' : 'regular',
      tokensFound: tokens.length,
      successCount: fcmResults.filter(r => r.success).length,
      results: fcmResults,
      notification: {
        title: arabicTitle,
        body: arabicBody,
        priority: priorityArabic,
        isEmergency,
        isMaintenance
      }
    }), {
      headers: { 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('💥 Function error:', error);
    return new Response(JSON.stringify({
      error: error.message,
      stack: error.stack
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
});
