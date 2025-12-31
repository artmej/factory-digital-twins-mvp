"""
🔧 ENHANCED PREDICTIVE MAINTENANCE
Advanced model for 1-2 day maintenance prediction
"""

import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestRegressor
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import mean_absolute_error
import joblib
from datetime import datetime, timedelta
import logging

# Setup logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class PredictiveMaintenanceAdvanced:
    """
    🔧 Advanced Predictive Maintenance Model
    Predicts exact time to failure with 24-48h anticipation
    """
    
    def __init__(self):
        """Initialize advanced predictive maintenance"""
        self.model = None
        self.scaler = StandardScaler()
        logger.info("🔧 Advanced Predictive Maintenance initialized")
        
        # Maintenance thresholds
        self.alert_thresholds = {
            'critical': 24,    # <24 hours until failure
            'warning': 48,     # <48 hours until failure  
            'preventive': 168  # <1 week until failure
        }
        
        # Machine-specific parameters
        self.machine_profiles = {
            'CNC_Mill': {'mtbf': 720, 'variance': 120},        # 30 days ±5 days
            'Injection_Molding': {'mtbf': 480, 'variance': 96},   # 20 days ±4 days
            'Assembly_Robot': {'mtbf': 1200, 'variance': 240},    # 50 days ±10 days
            'Conveyor_Belt': {'mtbf': 2160, 'variance': 360},     # 90 days ±15 days
            'Quality_Scanner': {'mtbf': 1440, 'variance': 288}    # 60 days ±12 days
        }

    def generate_enhanced_training_data(self, samples=15000):
        """
        🔧 Generate enhanced training data with time-to-failure labels
        """
        logger.info(f"🔧 Generating enhanced maintenance dataset ({samples} samples)...")
        
        machine_types = ['CNC_Mill', 'Injection_Molding', 'Assembly_Robot', 'Conveyor_Belt', 'Quality_Scanner']
        machine_ids = [f'M{str(i).zfill(3)}' for i in range(1, 31)]
        
        maintenance_data = []
        
        for i in range(samples):
            machine_id = np.random.choice(machine_ids)
            machine_type = np.random.choice(machine_types)
            
            # Get machine profile
            profile = self.machine_profiles[machine_type]
            
            # Time since last maintenance (hours)
            time_since_maintenance = np.random.uniform(0, profile['mtbf'] * 1.5)
            
            # Calculate degradation factors
            degradation_factor = min(time_since_maintenance / profile['mtbf'], 1.0)
            
            # Sensor readings with degradation
            vibration = self._generate_vibration_reading(degradation_factor, machine_type)
            temperature = self._generate_temperature_reading(degradation_factor, machine_type)
            pressure = self._generate_pressure_reading(degradation_factor, machine_type)
            current = self._generate_current_reading(degradation_factor, machine_type)
            noise_level = self._generate_noise_reading(degradation_factor, machine_type)
            oil_quality = self._generate_oil_quality(degradation_factor, machine_type)
            
            # Calculate remaining useful life (RUL) in hours
            remaining_life = self._calculate_remaining_life(
                degradation_factor, vibration, temperature, pressure, 
                current, noise_level, oil_quality, profile
            )
            
            # Determine maintenance urgency
            urgency = self._determine_urgency(remaining_life)
            
            maintenance_data.append({
                'machine_id': machine_id,
                'machine_type': machine_type,
                'time_since_maintenance': time_since_maintenance,
                'vibration_rms': vibration,
                'temperature_avg': temperature,
                'pressure_psi': pressure,
                'current_amp': current,
                'noise_db': noise_level,
                'oil_quality_index': oil_quality,
                'degradation_factor': degradation_factor,
                'remaining_useful_life_hours': remaining_life,
                'urgency_level': urgency,
                'needs_maintenance_24h': 1 if remaining_life <= 24 else 0,
                'needs_maintenance_48h': 1 if remaining_life <= 48 else 0,
                'needs_maintenance_1week': 1 if remaining_life <= 168 else 0
            })
        
        df = pd.DataFrame(maintenance_data)
        logger.info(f"✅ Enhanced dataset generated: {len(df)} samples")
        return df

    def _generate_vibration_reading(self, degradation, machine_type):
        """Generate realistic vibration readings"""
        base_values = {
            'CNC_Mill': 2.5,
            'Injection_Molding': 3.2, 
            'Assembly_Robot': 1.8,
            'Conveyor_Belt': 1.5,
            'Quality_Scanner': 0.8
        }
        
        base = base_values[machine_type]
        degradation_effect = degradation * base * 2.0  # Vibration increases with wear
        noise = np.random.normal(0, base * 0.1)
        
        return max(0.1, base + degradation_effect + noise)

    def _generate_temperature_reading(self, degradation, machine_type):
        """Generate realistic temperature readings"""
        base_temps = {
            'CNC_Mill': 45,
            'Injection_Molding': 65,
            'Assembly_Robot': 35,
            'Conveyor_Belt': 30,
            'Quality_Scanner': 25
        }
        
        base = base_temps[machine_type]
        degradation_effect = degradation * 25  # Higher temps with wear
        ambient_effect = np.random.normal(0, 3)
        
        return base + degradation_effect + ambient_effect

    def _generate_pressure_reading(self, degradation, machine_type):
        """Generate realistic pressure readings"""
        base_pressures = {
            'CNC_Mill': 0,      # No hydraulics
            'Injection_Molding': 2000,
            'Assembly_Robot': 120,
            'Conveyor_Belt': 0,
            'Quality_Scanner': 0
        }
        
        base = base_pressures[machine_type]
        if base == 0:
            return 0
            
        degradation_effect = -degradation * base * 0.2  # Pressure drops with wear
        noise = np.random.normal(0, base * 0.05)
        
        return max(base * 0.3, base + degradation_effect + noise)

    def _generate_current_reading(self, degradation, machine_type):
        """Generate motor current readings"""
        base_currents = {
            'CNC_Mill': 25,
            'Injection_Molding': 45,
            'Assembly_Robot': 15,
            'Conveyor_Belt': 8,
            'Quality_Scanner': 5
        }
        
        base = base_currents[machine_type]
        degradation_effect = degradation * base * 0.3  # Higher current with wear
        load_variation = np.random.normal(0, base * 0.1)
        
        return base + degradation_effect + load_variation

    def _generate_noise_reading(self, degradation, machine_type):
        """Generate noise level readings"""
        base_noise = {
            'CNC_Mill': 75,
            'Injection_Molding': 82,
            'Assembly_Robot': 68,
            'Conveyor_Belt': 65,
            'Quality_Scanner': 45
        }
        
        base = base_noise[machine_type]
        degradation_effect = degradation * 15  # Louder with wear
        ambient_noise = np.random.normal(0, 2)
        
        return base + degradation_effect + ambient_noise

    def _generate_oil_quality(self, degradation, machine_type):
        """Generate oil quality index (0-100)"""
        if machine_type in ['Quality_Scanner', 'Conveyor_Belt']:
            return 100  # No oil systems
            
        base_quality = 95
        degradation_effect = -degradation * 60  # Quality drops with use
        measurement_noise = np.random.normal(0, 3)
        
        return max(10, base_quality + degradation_effect + measurement_noise)

    def _calculate_remaining_life(self, degradation, vibration, temp, pressure, 
                                current, noise, oil_quality, profile):
        """
        🔧 Calculate remaining useful life using physics-informed model
        """
        # Base RUL from machine profile
        base_rul = profile['mtbf'] * (1 - degradation)
        
        # Sensor-based adjustments
        vibration_factor = min(vibration / 5.0, 2.0)  # High vibration = shorter life
        temp_factor = max(0.5, 1.0 - (temp - 30) / 100)  # High temp = shorter life
        
        # Oil quality effect (for machines with oil)
        oil_factor = 1.0
        if oil_quality < 100:  # Has oil system
            oil_factor = max(0.3, oil_quality / 100)
        
        # Current consumption effect
        current_factor = max(0.5, 1.0 - (current - 10) / 50)
        
        # Combined health score
        health_score = oil_factor * temp_factor * current_factor / vibration_factor
        
        # Calculated RUL with uncertainty
        calculated_rul = base_rul * health_score
        uncertainty = np.random.normal(0, profile['variance'] / 24)  # Convert days to hours
        
        return max(1, calculated_rul + uncertainty)

    def _determine_urgency(self, remaining_life):
        """Determine maintenance urgency level"""
        if remaining_life <= 24:
            return 'CRITICAL'
        elif remaining_life <= 48:
            return 'WARNING'
        elif remaining_life <= 168:
            return 'PREVENTIVE'
        else:
            return 'NORMAL'

    def train_model(self, data):
        """
        🚀 Train the enhanced predictive maintenance model
        """
        logger.info("🚀 Training enhanced predictive maintenance model...")
        
        # Feature selection
        feature_columns = [
            'time_since_maintenance', 'vibration_rms', 'temperature_avg',
            'pressure_psi', 'current_amp', 'noise_db', 'oil_quality_index'
        ]
        
        # Encode machine type
        data_encoded = pd.get_dummies(data, columns=['machine_type'], prefix='type')
        feature_columns.extend([col for col in data_encoded.columns if col.startswith('type_')])
        
        # Prepare features and targets
        X = data_encoded[feature_columns]
        y = data_encoded['remaining_useful_life_hours']
        
        # Split data
        X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
        
        # Scale features
        X_train_scaled = self.scaler.fit_transform(X_train)
        X_test_scaled = self.scaler.transform(X_test)
        
        # Train Random Forest model
        self.model = RandomForestRegressor(
            n_estimators=200,
            max_depth=15,
            min_samples_split=5,
            min_samples_leaf=2,
            random_state=42,
            n_jobs=-1
        )
        
        self.model.fit(X_train_scaled, y_train)
        
        # Evaluate model
        y_pred = self.model.predict(X_test_scaled)
        mae = mean_absolute_error(y_test, y_pred)
        
        # Calculate accuracy for different time windows
        accuracy_24h = self._calculate_classification_accuracy(y_test, y_pred, 24)
        accuracy_48h = self._calculate_classification_accuracy(y_test, y_pred, 48)
        
        logger.info(f"✅ Model trained successfully!")
        logger.info(f"📊 Mean Absolute Error: {mae:.2f} hours")
        logger.info(f"🎯 24h Prediction Accuracy: {accuracy_24h:.1f}%")
        logger.info(f"🎯 48h Prediction Accuracy: {accuracy_48h:.1f}%")
        
        return {
            'mae': mae,
            'accuracy_24h': accuracy_24h,
            'accuracy_48h': accuracy_48h,
            'model_trained': True
        }

    def _calculate_classification_accuracy(self, y_true, y_pred, threshold_hours):
        """Calculate classification accuracy for maintenance prediction"""
        true_maintenance = (y_true <= threshold_hours).astype(int)
        pred_maintenance = (y_pred <= threshold_hours).astype(int)
        
        correct_predictions = (true_maintenance == pred_maintenance).sum()
        total_predictions = len(y_true)
        
        return (correct_predictions / total_predictions) * 100

    def predict_maintenance_schedule(self, machine_data):
        """
        🔮 Predict maintenance schedule for next 7 days
        """
        if self.model is None:
            logger.error("❌ Model not trained yet!")
            return None
            
        # Prepare features
        feature_columns = [
            'time_since_maintenance', 'vibration_rms', 'temperature_avg',
            'pressure_psi', 'current_amp', 'noise_db', 'oil_quality_index'
        ]
        
        # Encode machine type
        machine_data_encoded = pd.get_dummies(machine_data, columns=['machine_type'], prefix='type')
        
        # Ensure all machine type columns exist
        for machine_type in ['CNC_Mill', 'Injection_Molding', 'Assembly_Robot', 'Conveyor_Belt', 'Quality_Scanner']:
            col_name = f'type_{machine_type}'
            if col_name not in machine_data_encoded.columns:
                machine_data_encoded[col_name] = 0
        
        # Add machine type columns to features
        type_columns = [col for col in machine_data_encoded.columns if col.startswith('type_')]
        feature_columns.extend(sorted(type_columns))
        
        X = machine_data_encoded[feature_columns]
        X_scaled = self.scaler.transform(X)
        
        # Predict remaining useful life
        predictions = self.model.predict(X_scaled)
        
        # Create maintenance schedule
        schedule = []
        current_time = datetime.now()
        
        for i, (_, row) in enumerate(machine_data.iterrows()):
            rul_hours = predictions[i]
            maintenance_time = current_time + timedelta(hours=rul_hours)
            urgency = self._determine_urgency(rul_hours)
            
            schedule.append({
                'machine_id': row['machine_id'],
                'machine_type': row['machine_type'],
                'remaining_life_hours': round(rul_hours, 1),
                'maintenance_due': maintenance_time,
                'urgency': urgency,
                'days_until_maintenance': round(rul_hours / 24, 1),
                'alert_24h': rul_hours <= 24,
                'alert_48h': rul_hours <= 48,
                'current_status': self._get_status_message(rul_hours)
            })
        
        return pd.DataFrame(schedule)

    def _get_status_message(self, rul_hours):
        """Get human-readable status message"""
        if rul_hours <= 8:
            return "🚨 URGENT MAINTENANCE - Stop production"
        elif rul_hours <= 24:
            return "⚠️ CRITICAL MAINTENANCE - Schedule immediately"
        elif rul_hours <= 48:
            return "🟡 MAINTENANCE REQUIRED - Schedule in 1-2 days"
        elif rul_hours <= 168:
            return "🟢 PREVENTIVE MAINTENANCE - Schedule this week"
        else:
            return "✅ NORMAL STATUS - No maintenance required"

    def save_model(self, filepath):
        """Save trained model"""
        if self.model is not None:
            joblib.dump({
                'model': self.model,
                'scaler': self.scaler,
                'thresholds': self.alert_thresholds
            }, filepath)
            logger.info(f"💾 Model saved to {filepath}")

    def load_model(self, filepath):
        """Load trained model"""
        model_data = joblib.load(filepath)
        self.model = model_data['model']
        self.scaler = model_data['scaler']
        self.alert_thresholds = model_data['thresholds']
        logger.info(f"📂 Model loaded from {filepath}")

def main():
    """
    🚀 Demo: Enhanced Predictive Maintenance with 1-2 day predictions
    """
    logger.info("🔧 ENHANCED PREDICTIVE MAINTENANCE DEMO")
    logger.info("=" * 60)
    
    # Initialize model
    pm = PredictiveMaintenanceAdvanced()
    
    # Generate training data
    training_data = pm.generate_enhanced_training_data(samples=15000)
    
    # Train model
    results = pm.train_model(training_data)
    
    # Generate current machine status data
    current_machines = []
    machine_types = ['CNC_Mill', 'Injection_Molding', 'Assembly_Robot', 'Conveyor_Belt', 'Quality_Scanner']
    
    for i in range(1, 11):  # 10 machines for demo
        machine_type = np.random.choice(machine_types)
        
        # Simulate current machine state
        degradation = np.random.uniform(0.3, 0.9)  # Some wear
        
        current_machines.append({
            'machine_id': f'M{str(i).zfill(3)}',
            'machine_type': machine_type,
            'time_since_maintenance': np.random.uniform(100, 600),
            'vibration_rms': pm._generate_vibration_reading(degradation, machine_type),
            'temperature_avg': pm._generate_temperature_reading(degradation, machine_type),
            'pressure_psi': pm._generate_pressure_reading(degradation, machine_type),
            'current_amp': pm._generate_current_reading(degradation, machine_type),
            'noise_db': pm._generate_noise_reading(degradation, machine_type),
            'oil_quality_index': pm._generate_oil_quality(degradation, machine_type)
        })
    
    machine_status_df = pd.DataFrame(current_machines)
    
    # Predict maintenance schedule
    schedule = pm.predict_maintenance_schedule(machine_status_df)
    
    # Display results
    logger.info("\n📅 MAINTENANCE SCHEDULE (Next 7 days)")
    logger.info("=" * 80)
    
    # Sort by urgency
    schedule_sorted = schedule.sort_values('remaining_life_hours')
    
    for _, machine in schedule_sorted.iterrows():
        logger.info(f"\n🔧 {machine['machine_id']} ({machine['machine_type']})")
        logger.info(f"   ⏰ {machine['days_until_maintenance']:.1f} days until maintenance")
        logger.info(f"   📊 {machine['current_status']}")
        logger.info(f"   📅 Scheduled date: {machine['maintenance_due'].strftime('%Y-%m-%d %H:%M')}")
    
    # Summary statistics
    critical_machines = len(schedule[schedule['alert_24h']])
    warning_machines = len(schedule[schedule['alert_48h']])
    
    logger.info(f"\n📊 EXECUTIVE SUMMARY:")
    logger.info(f"   🚨 CRITICAL maintenance (24h): {critical_machines} machines")
    logger.info(f"   ⚠️ WARNING maintenance (48h): {warning_machines} machines")
    logger.info(f"   🎯 Model accuracy 24h: {results['accuracy_24h']:.1f}%")
    logger.info(f"   🎯 Model accuracy 48h: {results['accuracy_48h']:.1f}%")
    
    # Save model
    pm.save_model('enhanced_predictive_maintenance.pkl')
    
    logger.info("\n✅ DEMO COMPLETED - Model ready for production!")
    
    return schedule

if __name__ == "__main__":
    maintenance_schedule = main()