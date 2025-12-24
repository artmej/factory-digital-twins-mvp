import io from 'socket.io-client';
import AsyncStorage from '@react-native-async-storage/async-storage';
import PushNotification from 'react-native-push-notification';
import NetInfo from '@react-native-community/netinfo';

// 🔗 Mobile API Client for Smart Factory Integration
class SmartFactoryAPI {
  constructor() {
    this.baseURL = 'http://localhost:3000'; // Factory dashboard server
    this.socket = null;
    this.isConnected = false;
    this.reconnectAttempts = 0;
    this.maxReconnectAttempts = 5;
    
    // Initialize notification system
    this.initializeNotifications();
    
    // Monitor network connectivity
    this.setupNetworkMonitoring();
  }

  // 🔔 Initialize Push Notifications
  initializeNotifications() {
    PushNotification.configure({
      onRegister: function (token) {
        console.log('📱 Push notification token:', token);
      },
      onNotification: function (notification) {
        console.log('📨 Notification received:', notification);
        
        // Handle notification tap
        if (notification.userInteraction) {
          // Navigate to relevant screen
          console.log('User tapped notification');
        }
      },
      permissions: {
        alert: true,
        badge: true,
        sound: true,
      },
      popInitialNotification: true,
      requestPermissions: true,
    });

    // Create notification channels
    PushNotification.createChannel(
      {
        channelId: "factory-alerts",
        channelName: "Factory Alerts",
        channelDescription: "Critical factory maintenance alerts",
        importance: 4,
        vibrate: true,
      },
      (created) => console.log(`Notification channel created: ${created}`)
    );
  }

  // 🌐 Network Monitoring
  setupNetworkMonitoring() {
    NetInfo.addEventListener(state => {
      console.log('📶 Network state:', state.isConnected);
      
      if (state.isConnected && !this.isConnected) {
        this.connect();
      } else if (!state.isConnected && this.isConnected) {
        this.disconnect();
      }
    });
  }

  // 🔌 Connect to Factory Dashboard WebSocket
  async connect() {
    try {
      console.log('🔌 Connecting to Smart Factory dashboard...');
      
      this.socket = io(this.baseURL, {
        transports: ['websocket'],
        timeout: 5000,
        reconnection: true,
        reconnectionAttempts: this.maxReconnectAttempts,
        reconnectionDelay: 2000
      });

      this.socket.on('connect', () => {
        console.log('✅ Connected to factory dashboard');
        this.isConnected = true;
        this.reconnectAttempts = 0;
        
        // Subscribe to factory updates
        this.socket.emit('mobile-client-connected', {
          clientType: 'mobile',
          timestamp: new Date().toISOString()
        });
      });

      // 📊 Factory data updates
      this.socket.on('factory-update', (data) => {
        this.handleFactoryUpdate(data);
      });

      // 🚨 Critical alerts
      this.socket.on('critical-alert', (alert) => {
        this.handleCriticalAlert(alert);
      });

      // 🔮 ML insights
      this.socket.on('ml-insights', (insights) => {
        this.handleMLInsights(insights);
      });

      // Connection error handling
      this.socket.on('connect_error', (error) => {
        console.error('❌ Connection error:', error);
        this.isConnected = false;
        this.reconnectAttempts++;
        
        if (this.reconnectAttempts >= this.maxReconnectAttempts) {
          console.log('🔄 Max reconnection attempts reached, switching to offline mode');
          this.enableOfflineMode();
        }
      });

      this.socket.on('disconnect', (reason) => {
        console.log('🔌 Disconnected:', reason);
        this.isConnected = false;
      });

    } catch (error) {
      console.error('❌ Failed to connect:', error);
      this.enableOfflineMode();
    }
  }

  // 📱 Handle Factory Data Updates
  handleFactoryUpdate(data) {
    console.log('📊 Factory update received:', data);
    
    // Store data locally for offline access
    AsyncStorage.setItem('factory-data', JSON.stringify({
      ...data,
      lastUpdate: new Date().toISOString()
    }));

    // Trigger app state update (would be passed to React components)
    if (this.onDataUpdate) {
      this.onDataUpdate(data);
    }
  }

  // 🚨 Handle Critical Alerts
  handleCriticalAlert(alert) {
    console.log('🚨 Critical alert:', alert);
    
    // Show push notification
    PushNotification.localNotification({
      channelId: "factory-alerts",
      title: `🚨 ${alert.title}`,
      message: alert.message,
      priority: 'max',
      importance: 'high',
      vibrate: true,
      vibration: 300,
      playSound: true,
      soundName: 'default',
      actions: ['View', 'Dismiss'],
      userInfo: { alertId: alert.id, type: alert.type }
    });

    // Store alert for later reference
    this.storeAlert(alert);
  }

  // 🔮 Handle ML Insights
  handleMLInsights(insights) {
    console.log('🔮 ML insights received:', insights);
    
    // Store insights locally
    AsyncStorage.setItem('ml-insights', JSON.stringify({
      ...insights,
      timestamp: new Date().toISOString()
    }));

    // Show notification for important insights
    if (insights.severity === 'high') {
      PushNotification.localNotification({
        channelId: "factory-alerts",
        title: '🔮 AI Insight',
        message: insights.summary,
        priority: 'default',
        userInfo: { type: 'ml-insight', insightId: insights.id }
      });
    }
  }

  // 💾 Store Alert Locally
  async storeAlert(alert) {
    try {
      const existingAlerts = await AsyncStorage.getItem('stored-alerts');
      const alerts = existingAlerts ? JSON.parse(existingAlerts) : [];
      
      alerts.unshift({
        ...alert,
        receivedAt: new Date().toISOString(),
        read: false
      });

      // Keep only last 50 alerts
      const trimmedAlerts = alerts.slice(0, 50);
      
      await AsyncStorage.setItem('stored-alerts', JSON.stringify(trimmedAlerts));
    } catch (error) {
      console.error('❌ Failed to store alert:', error);
    }
  }

  // 📱 Offline Mode Operations
  async enableOfflineMode() {
    console.log('📴 Enabling offline mode');
    
    try {
      // Load cached data
      const cachedData = await AsyncStorage.getItem('factory-data');
      const cachedInsights = await AsyncStorage.getItem('ml-insights');
      
      if (cachedData) {
        const data = JSON.parse(cachedData);
        console.log('📂 Loaded cached factory data from:', data.lastUpdate);
        
        if (this.onDataUpdate) {
          this.onDataUpdate({
            ...data,
            isOffline: true
          });
        }
      }

      // Show offline notification
      PushNotification.localNotification({
        channelId: "factory-alerts",
        title: '📴 Offline Mode',
        message: 'Using cached factory data. Will reconnect automatically.',
        priority: 'low'
      });

    } catch (error) {
      console.error('❌ Failed to enable offline mode:', error);
    }
  }

  // 📊 Get Cached Factory Data
  async getCachedData() {
    try {
      const cachedData = await AsyncStorage.getItem('factory-data');
      return cachedData ? JSON.parse(cachedData) : null;
    } catch (error) {
      console.error('❌ Failed to get cached data:', error);
      return null;
    }
  }

  // 🚨 Get Stored Alerts
  async getStoredAlerts() {
    try {
      const alerts = await AsyncStorage.getItem('stored-alerts');
      return alerts ? JSON.parse(alerts) : [];
    } catch (error) {
      console.error('❌ Failed to get stored alerts:', error);
      return [];
    }
  }

  // ✅ Mark Alert as Read
  async markAlertAsRead(alertId) {
    try {
      const alerts = await this.getStoredAlerts();
      const updatedAlerts = alerts.map(alert => 
        alert.id === alertId ? { ...alert, read: true } : alert
      );
      
      await AsyncStorage.setItem('stored-alerts', JSON.stringify(updatedAlerts));
    } catch (error) {
      console.error('❌ Failed to mark alert as read:', error);
    }
  }

  // 🔧 Send Maintenance Action
  sendMaintenanceAction(action) {
    if (this.isConnected && this.socket) {
      console.log('🔧 Sending maintenance action:', action);
      
      this.socket.emit('maintenance-action', {
        action: action.type,
        machineId: action.machineId,
        priority: action.priority,
        requestedBy: 'mobile-app',
        timestamp: new Date().toISOString()
      });
    } else {
      // Queue action for when connection is restored
      this.queueAction(action);
    }
  }

  // 📞 Request Technician Call
  requestTechnicianCall(machineId, urgency) {
    const action = {
      type: 'technician-call',
      machineId,
      urgency,
      timestamp: new Date().toISOString()
    };

    if (this.isConnected && this.socket) {
      this.socket.emit('technician-request', action);
      
      // Show confirmation
      PushNotification.localNotification({
        channelId: "factory-alerts",
        title: '📞 Technician Called',
        message: `Technician request sent for ${machineId}`,
        priority: 'default'
      });
    } else {
      this.queueAction(action);
    }
  }

  // 📋 Queue Actions for Later
  async queueAction(action) {
    try {
      const queuedActions = await AsyncStorage.getItem('queued-actions');
      const actions = queuedActions ? JSON.parse(queuedActions) : [];
      
      actions.push({
        ...action,
        queuedAt: new Date().toISOString()
      });
      
      await AsyncStorage.setItem('queued-actions', JSON.stringify(actions));
      
      // Notify user
      PushNotification.localNotification({
        channelId: "factory-alerts",
        title: '📋 Action Queued',
        message: 'Action will be sent when connection is restored',
        priority: 'low'
      });
    } catch (error) {
      console.error('❌ Failed to queue action:', error);
    }
  }

  // 🔄 Process Queued Actions
  async processQueuedActions() {
    if (!this.isConnected) return;

    try {
      const queuedActions = await AsyncStorage.getItem('queued-actions');
      if (!queuedActions) return;

      const actions = JSON.parse(queuedActions);
      
      for (const action of actions) {
        console.log('🔄 Processing queued action:', action);
        
        if (action.type === 'technician-call') {
          this.socket.emit('technician-request', action);
        } else {
          this.socket.emit('maintenance-action', action);
        }
      }

      // Clear processed actions
      await AsyncStorage.removeItem('queued-actions');
      
      if (actions.length > 0) {
        PushNotification.localNotification({
          channelId: "factory-alerts",
          title: '✅ Actions Processed',
          message: `${actions.length} queued actions have been sent`,
          priority: 'low'
        });
      }
    } catch (error) {
      console.error('❌ Failed to process queued actions:', error);
    }
  }

  // 🔌 Disconnect
  disconnect() {
    if (this.socket) {
      this.socket.disconnect();
      this.socket = null;
    }
    this.isConnected = false;
    console.log('🔌 Disconnected from factory dashboard');
  }

  // 📊 Set Data Update Callback
  setDataUpdateCallback(callback) {
    this.onDataUpdate = callback;
  }
}

// 📱 Export API client
export default new SmartFactoryAPI();