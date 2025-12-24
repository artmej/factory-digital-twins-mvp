import React, { useState, useEffect } from 'react';
import { 
  View, 
  Text, 
  StyleSheet, 
  ScrollView, 
  RefreshControl,
  Alert,
  TouchableOpacity,
  Switch,
  Dimensions
} from 'react-native';
import { LineChart, BarChart, ProgressChart } from 'react-native-chart-kit';
import Icon from 'react-native-vector-icons/MaterialIcons';

const { width } = Dimensions.get('window');

// 📱 Smart Factory Mobile Dashboard
const SmartFactoryApp = () => {
  const [factoryData, setFactoryData] = useState({
    production: {
      oee: 0.873,
      throughput: 950,
      quality: 0.948,
      availability: 0.921
    },
    maintenance: {
      riskScores: { machineA: 42, machineB: 18, machineC: 12 },
      predictions: [],
      alerts: []
    },
    ml: {
      healthScores: { machineA: 75, machineB: 88, machineC: 92 },
      anomalies: [],
      insights: []
    }
  });

  const [isRefreshing, setIsRefreshing] = useState(false);
  const [notifications, setNotifications] = useState(true);
  const [selectedMachine, setSelectedMachine] = useState('machineA');

  // 🔄 Refresh Factory Data
  const refreshData = async () => {
    setIsRefreshing(true);
    
    // Simulate API call
    setTimeout(() => {
      setFactoryData(prev => ({
        ...prev,
        production: {
          oee: 0.85 + Math.random() * 0.1,
          throughput: 900 + Math.random() * 100,
          quality: 0.92 + Math.random() * 0.06,
          availability: 0.88 + Math.random() * 0.08
        },
        maintenance: {
          ...prev.maintenance,
          riskScores: {
            machineA: Math.round(30 + Math.random() * 40),
            machineB: Math.round(10 + Math.random() * 30),
            machineC: Math.round(5 + Math.random() * 25)
          }
        },
        ml: {
          ...prev.ml,
          healthScores: {
            machineA: Math.round(70 + Math.random() * 25),
            machineB: Math.round(80 + Math.random() * 15),
            machineC: Math.round(85 + Math.random() * 12)
          }
        }
      }));
      
      setIsRefreshing(false);
    }, 1500);
  };

  // 📊 Chart configurations
  const chartConfig = {
    backgroundGradientFrom: '#1E3A8A',
    backgroundGradientTo: '#3B82F6',
    color: (opacity = 1) => `rgba(255, 255, 255, ${opacity})`,
    strokeWidth: 2,
    barPercentage: 0.5,
    useShadowColorFromDataset: false
  };

  const oeeTrendData = {
    labels: ['10:00', '10:30', '11:00', '11:30', '12:00', '12:30'],
    datasets: [{
      data: [85, 87, 89, 86, 88, factoryData.production.oee * 100],
      color: (opacity = 1) => `rgba(134, 239, 172, ${opacity})`,
      strokeWidth: 2
    }]
  };

  const riskScoreData = {
    labels: ['Machine A', 'Machine B', 'Machine C'],
    datasets: [{
      data: [
        factoryData.maintenance.riskScores.machineA,
        factoryData.maintenance.riskScores.machineB,
        factoryData.maintenance.riskScores.machineC
      ]
    }]
  };

  // 🚨 Handle Alert Actions
  const handleAlertAction = (alertType) => {
    Alert.alert(
      'Alert Action',
      `Would you like to take action on this ${alertType} alert?`,
      [
        { text: 'Dismiss', style: 'cancel' },
        { text: 'Schedule Maintenance', onPress: () => console.log('Maintenance scheduled') },
        { text: 'Call Technician', onPress: () => console.log('Technician called') }
      ]
    );
  };

  // 🎨 Risk color coding
  const getRiskColor = (score) => {
    if (score >= 70) return '#EF4444';
    if (score >= 40) return '#F59E0B';
    return '#10B981';
  };

  const getHealthColor = (score) => {
    if (score >= 80) return '#10B981';
    if (score >= 60) return '#F59E0B';
    return '#EF4444';
  };

  // Component rendering
  return (
    <ScrollView 
      style={styles.container}
      refreshControl={
        <RefreshControl refreshing={isRefreshing} onRefresh={refreshData} />
      }
    >
      {/* Header */}
      <View style={styles.header}>
        <Text style={styles.headerTitle}>🏭 Smart Factory</Text>
        <Text style={styles.headerSubtitle}>Predictive Maintenance Dashboard</Text>
        <View style={styles.headerControls}>
          <Text style={styles.notificationLabel}>Notifications</Text>
          <Switch
            value={notifications}
            onValueChange={setNotifications}
            trackColor={{ false: '#767577', true: '#34D399' }}
          />
        </View>
      </View>

      {/* Production Overview Cards */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>📊 Production Overview</Text>
        <View style={styles.cardGrid}>
          <View style={[styles.card, styles.productionCard]}>
            <Text style={styles.cardTitle}>OEE</Text>
            <Text style={styles.cardValue}>{(factoryData.production.oee * 100).toFixed(1)}%</Text>
            <View style={styles.progressBar}>
              <View style={[styles.progressFill, { width: `${factoryData.production.oee * 100}%` }]} />
            </View>
          </View>
          
          <View style={[styles.card, styles.productionCard]}>
            <Text style={styles.cardTitle}>Throughput</Text>
            <Text style={styles.cardValue}>{Math.round(factoryData.production.throughput)}</Text>
            <Text style={styles.cardUnit}>units/hour</Text>
          </View>
          
          <View style={[styles.card, styles.productionCard]}>
            <Text style={styles.cardTitle}>Quality</Text>
            <Text style={styles.cardValue}>{(factoryData.production.quality * 100).toFixed(1)}%</Text>
          </View>
          
          <View style={[styles.card, styles.productionCard]}>
            <Text style={styles.cardTitle}>Availability</Text>
            <Text style={styles.cardValue}>{(factoryData.production.availability * 100).toFixed(1)}%</Text>
          </View>
        </View>
      </View>

      {/* OEE Trend Chart */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>📈 OEE Trend (Last 6 Hours)</Text>
        <LineChart
          data={oeeTrendData}
          width={width - 40}
          height={200}
          chartConfig={chartConfig}
          style={styles.chart}
          bezier
        />
      </View>

      {/* AI Risk Assessment */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>🔮 AI Risk Assessment</Text>
        <BarChart
          data={riskScoreData}
          width={width - 40}
          height={200}
          chartConfig={chartConfig}
          style={styles.chart}
          showValuesOnTopOfBars={true}
        />
        
        {/* Machine Selection */}
        <View style={styles.machineSelector}>
          {['machineA', 'machineB', 'machineC'].map(machine => (
            <TouchableOpacity
              key={machine}
              style={[
                styles.machineButton,
                selectedMachine === machine && styles.machineButtonActive
              ]}
              onPress={() => setSelectedMachine(machine)}
            >
              <Text style={[
                styles.machineButtonText,
                selectedMachine === machine && styles.machineButtonTextActive
              ]}>
                {machine.replace('machine', 'Machine ')}
              </Text>
            </TouchableOpacity>
          ))}
        </View>

        {/* Selected Machine Details */}
        <View style={styles.machineDetails}>
          <View style={styles.detailRow}>
            <Text style={styles.detailLabel}>Risk Score:</Text>
            <Text style={[
              styles.detailValue,
              { color: getRiskColor(factoryData.maintenance.riskScores[selectedMachine]) }
            ]}>
              {factoryData.maintenance.riskScores[selectedMachine]}%
            </Text>
          </View>
          
          <View style={styles.detailRow}>
            <Text style={styles.detailLabel}>Health Score:</Text>
            <Text style={[
              styles.detailValue,
              { color: getHealthColor(factoryData.ml.healthScores[selectedMachine]) }
            ]}>
              {factoryData.ml.healthScores[selectedMachine]}%
            </Text>
          </View>
          
          <View style={styles.detailRow}>
            <Text style={styles.detailLabel}>Status:</Text>
            <Text style={[styles.detailValue, { color: '#10B981' }]}>
              {factoryData.maintenance.riskScores[selectedMachine] > 40 ? '⚠️ Attention Needed' : '✅ Normal'}
            </Text>
          </View>
        </View>
      </View>

      {/* Live Alerts */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>🚨 Live Alerts & AI Insights</Text>
        
        <TouchableOpacity 
          style={[styles.alert, styles.alertWarning]}
          onPress={() => handleAlertAction('maintenance')}
        >
          <Icon name="warning" size={24} color="#F59E0B" />
          <View style={styles.alertContent}>
            <Text style={styles.alertTitle}>Preventive Maintenance Due</Text>
            <Text style={styles.alertMessage}>
              Machine A showing early wear indicators. AI recommends maintenance within 48 hours.
            </Text>
          </View>
          <Icon name="chevron-right" size={24} color="#666" />
        </TouchableOpacity>

        <TouchableOpacity 
          style={[styles.alert, styles.alertInfo]}
          onPress={() => handleAlertAction('optimization')}
        >
          <Icon name="auto-awesome" size={24} color="#3B82F6" />
          <View style={styles.alertContent}>
            <Text style={styles.alertTitle}>AI Optimization Suggestion</Text>
            <Text style={styles.alertMessage}>
              ML models suggest adjusting Line B parameters for 3% efficiency gain.
            </Text>
          </View>
          <Icon name="chevron-right" size={24} color="#666" />
        </TouchableOpacity>

        <TouchableOpacity 
          style={[styles.alert, styles.alertSuccess]}
          onPress={() => handleAlertAction('success')}
        >
          <Icon name="check-circle" size={24} color="#10B981" />
          <View style={styles.alertContent}>
            <Text style={styles.alertTitle}>Maintenance Completed</Text>
            <Text style={styles.alertMessage}>
              Machine C maintenance successful. Health score improved to 92%.
            </Text>
          </View>
          <Icon name="chevron-right" size={24} color="#666" />
        </TouchableOpacity>
      </View>

      {/* Business Impact */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>💰 Business Impact</Text>
        <View style={styles.cardGrid}>
          <View style={[styles.card, styles.impactCard]}>
            <Text style={styles.cardTitle}>Cost Avoidance</Text>
            <Text style={styles.cardValue}>$125k</Text>
            <Text style={styles.cardSubtext}>This Month</Text>
          </View>
          
          <View style={[styles.card, styles.impactCard]}>
            <Text style={styles.cardTitle}>Downtime Reduction</Text>
            <Text style={styles.cardValue}>38%</Text>
            <Text style={styles.cardSubtext}>vs Last Year</Text>
          </View>
          
          <View style={[styles.card, styles.impactCard]}>
            <Text style={styles.cardTitle}>Annual ROI</Text>
            <Text style={styles.cardValue}>$2.2M</Text>
            <Text style={styles.cardSubtext}>Projected</Text>
          </View>
          
          <View style={[styles.card, styles.impactCard]}>
            <Text style={styles.cardTitle}>AI Accuracy</Text>
            <Text style={styles.cardValue}>94.7%</Text>
            <Text style={styles.cardSubtext}>Failure Prediction</Text>
          </View>
        </View>
      </View>

      {/* Action Buttons */}
      <View style={styles.actionSection}>
        <TouchableOpacity style={[styles.actionButton, styles.primaryButton]}>
          <Icon name="build" size={20} color="#FFF" />
          <Text style={styles.buttonText}>Schedule Maintenance</Text>
        </TouchableOpacity>
        
        <TouchableOpacity style={[styles.actionButton, styles.secondaryButton]}>
          <Icon name="phone" size={20} color="#3B82F6" />
          <Text style={[styles.buttonText, { color: '#3B82F6' }]}>Call Technician</Text>
        </TouchableOpacity>
      </View>

      {/* Footer */}
      <View style={styles.footer}>
        <Text style={styles.footerText}>
          🎯 Case Study #36: Smart Factory Predictive Maintenance
        </Text>
        <Text style={styles.footerSubtext}>
          Last updated: {new Date().toLocaleTimeString()}
        </Text>
      </View>
    </ScrollView>
  );
};

// 🎨 Styles
const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F8FAFC',
  },
  header: {
    backgroundColor: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
    padding: 20,
    paddingTop: 50,
  },
  headerTitle: {
    fontSize: 28,
    fontWeight: 'bold',
    color: '#FFF',
    textAlign: 'center',
  },
  headerSubtitle: {
    fontSize: 16,
    color: '#E2E8F0',
    textAlign: 'center',
    marginTop: 5,
  },
  headerControls: {
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    marginTop: 15,
  },
  notificationLabel: {
    color: '#FFF',
    marginRight: 10,
  },
  section: {
    margin: 20,
  },
  sectionTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#1F2937',
    marginBottom: 15,
  },
  cardGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'space-between',
  },
  card: {
    backgroundColor: '#FFF',
    borderRadius: 12,
    padding: 15,
    marginBottom: 15,
    width: '48%',
    elevation: 2,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
  },
  productionCard: {
    borderLeft: '4px solid #10B981',
  },
  impactCard: {
    borderLeft: '4px solid #3B82F6',
  },
  cardTitle: {
    fontSize: 14,
    color: '#6B7280',
    marginBottom: 5,
  },
  cardValue: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#1F2937',
  },
  cardUnit: {
    fontSize: 12,
    color: '#9CA3AF',
  },
  cardSubtext: {
    fontSize: 12,
    color: '#6B7280',
    marginTop: 5,
  },
  progressBar: {
    height: 6,
    backgroundColor: '#E5E7EB',
    borderRadius: 3,
    marginTop: 10,
  },
  progressFill: {
    height: '100%',
    backgroundColor: '#10B981',
    borderRadius: 3,
  },
  chart: {
    marginVertical: 10,
    borderRadius: 12,
  },
  machineSelector: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    marginVertical: 15,
  },
  machineButton: {
    paddingHorizontal: 15,
    paddingVertical: 8,
    borderRadius: 20,
    backgroundColor: '#E5E7EB',
  },
  machineButtonActive: {
    backgroundColor: '#3B82F6',
  },
  machineButtonText: {
    color: '#6B7280',
    fontWeight: '500',
  },
  machineButtonTextActive: {
    color: '#FFF',
  },
  machineDetails: {
    backgroundColor: '#FFF',
    borderRadius: 12,
    padding: 15,
    marginTop: 10,
  },
  detailRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingVertical: 8,
  },
  detailLabel: {
    fontSize: 16,
    color: '#6B7280',
  },
  detailValue: {
    fontSize: 16,
    fontWeight: 'bold',
  },
  alert: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FFF',
    borderRadius: 12,
    padding: 15,
    marginBottom: 10,
    elevation: 1,
  },
  alertWarning: {
    borderLeft: '4px solid #F59E0B',
  },
  alertInfo: {
    borderLeft: '4px solid #3B82F6',
  },
  alertSuccess: {
    borderLeft: '4px solid #10B981',
  },
  alertContent: {
    flex: 1,
    marginLeft: 15,
  },
  alertTitle: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#1F2937',
    marginBottom: 5,
  },
  alertMessage: {
    fontSize: 14,
    color: '#6B7280',
  },
  actionSection: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    paddingHorizontal: 20,
    marginBottom: 20,
  },
  actionButton: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingVertical: 12,
    borderRadius: 25,
    minWidth: 140,
    justifyContent: 'center',
  },
  primaryButton: {
    backgroundColor: '#3B82F6',
  },
  secondaryButton: {
    backgroundColor: '#FFF',
    borderWidth: 2,
    borderColor: '#3B82F6',
  },
  buttonText: {
    color: '#FFF',
    fontWeight: 'bold',
    marginLeft: 8,
  },
  footer: {
    backgroundColor: '#374151',
    padding: 20,
    alignItems: 'center',
  },
  footerText: {
    color: '#FFF',
    fontSize: 16,
    fontWeight: 'bold',
    textAlign: 'center',
  },
  footerSubtext: {
    color: '#9CA3AF',
    fontSize: 14,
    marginTop: 5,
  },
});

export default SmartFactoryApp;