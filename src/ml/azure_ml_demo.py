#!/usr/bin/env python3
"""
Smart Factory ML Studio - Demo Training Script  
Simplified version for quick testing and demo purposes
"""

import os
import json
import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import logging

# ML imports
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report, accuracy_score
from sklearn.preprocessing import LabelEncoder

# Setup logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class SmartFactoryMLDemo:
    """
    🏭 Smart Factory ML Demo - Simplified Implementation
    Quick demo for Azure ML Studio integration
    """
    
    def __init__(self):
        """Initialize configuration"""
        self.subscription_id = os.getenv('AZURE_SUBSCRIPTION_ID')
        self.resource_group = os.getenv('RESOURCE_GROUP', 'rg-smartfactory-prod')
        self.workspace_name = os.getenv('ML_WORKSPACE_NAME', 'smartfactory-ml-prod')
        
        logger.info(f"🤖 ML Demo initialized for workspace: {self.workspace_name}")

    def generate_demo_data(self, samples=10000) -> pd.DataFrame:
        """
        🔧 Generate demo factory training data
        """
        logger.info(f"🔧 Generating {samples} demo samples...")
        
        # Machine types
        machine_types = ['CNC_Mill', 'Injection_Molding', 'Assembly_Robot', 'Conveyor_Belt']
        machine_ids = [f'M{str(i).zfill(3)}' for i in range(1, 21)]  # 20 machines
        
        data = []
        
        for i in range(samples):
            machine_id = np.random.choice(machine_ids)
            machine_type = np.random.choice(machine_types)
            
            # Basic sensor readings
            runtime_hours = np.random.uniform(0, 8760)
            temperature = np.random.normal(50, 15) + (runtime_hours / 8760) * 10  # aging effect
            vibration = np.random.normal(2, 0.8) + (runtime_hours / 5000) * 1.5   # wear effect
            pressure = np.random.normal(120, 20) if machine_type == 'Injection_Molding' else 0
            
            # Simple failure logic
            failure_probability = 0.0
            if runtime_hours > 6000:
                failure_probability += 0.3
            if temperature > 70:
                failure_probability += 0.4
            if vibration > 3.5:
                failure_probability += 0.3
            
            failure_probability = min(1.0, failure_probability + np.random.uniform(0, 0.1))
            needs_maintenance = 1 if failure_probability > 0.6 else 0
            
            data.append({
                'machine_id': machine_id,
                'machine_type': machine_type,
                'runtime_hours': runtime_hours,
                'temperature': temperature,
                'vibration': vibration,
                'pressure': pressure,
                'failure_probability': failure_probability,
                'needs_maintenance': needs_maintenance
            })
        
        df = pd.DataFrame(data)
        logger.info(f"✅ Generated demo dataset: {df.shape}")
        return df

    def train_demo_model(self, data: pd.DataFrame) -> dict:
        """
        🎯 Train simple Random Forest model for demo
        """
        logger.info("🎯 Training demo Random Forest model...")
        
        # Prepare features
        le_machine_type = LabelEncoder()
        data['machine_type_encoded'] = le_machine_type.fit_transform(data['machine_type'])
        
        feature_cols = ['runtime_hours', 'temperature', 'vibration', 'pressure', 'machine_type_encoded']
        X = data[feature_cols].fillna(0)
        y = data['needs_maintenance']
        
        # Train/test split
        X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
        
        # Train Random Forest
        model = RandomForestClassifier(
            n_estimators=100,
            max_depth=10,
            random_state=42
        )
        
        model.fit(X_train, y_train)
        
        # Evaluate
        predictions = model.predict(X_test)
        accuracy = accuracy_score(y_test, predictions)
        
        logger.info(f"✅ Demo Model Accuracy: {accuracy:.3f}")
        
        return {
            'model': model,
            'accuracy': accuracy,
            'feature_importance': dict(zip(feature_cols, model.feature_importances_)),
            'label_encoder': le_machine_type
        }

    def generate_business_report(self, model_results: dict, data: pd.DataFrame) -> dict:
        """
        💰 Generate business impact demo report
        """
        logger.info("💰 Generating business impact demo...")
        
        accuracy = model_results['accuracy']
        total_machines = data['machine_id'].nunique()
        
        # Business calculations
        monthly_downtime_hours = 120  # Average per machine
        downtime_cost_per_hour = 5000  # USD
        annual_baseline_cost = total_machines * monthly_downtime_hours * 12 * downtime_cost_per_hour
        
        # AI improvements
        downtime_reduction = accuracy * 0.35  # Max 35% reduction
        annual_savings = annual_baseline_cost * downtime_reduction
        
        roi_report = {
            'demo_metrics': {
                'total_machines': total_machines,
                'model_accuracy': accuracy,
                'baseline_annual_cost_usd': annual_baseline_cost,
                'predicted_savings_usd': annual_savings,
                'downtime_reduction_pct': downtime_reduction * 100,
                'roi_3_year_pct': (annual_savings * 3 / 500000 - 1) * 100
            },
            'feature_importance': model_results['feature_importance']
        }
        
        logger.info(f"💰 Demo Results:")
        logger.info(f"   Model Accuracy: {accuracy:.1%}")
        logger.info(f"   Predicted Annual Savings: ${annual_savings:,.2f}")
        logger.info(f"   Expected Downtime Reduction: {downtime_reduction*100:.1f}%")
        
        return roi_report

    def save_demo_results(self, results: dict):
        """Save demo results to files"""
        logger.info("💾 Saving demo results...")
        
        os.makedirs('./demo_results', exist_ok=True)
        
        with open('./demo_results/ml_demo_results.json', 'w') as f:
            json.dump(results, f, indent=2, default=str)
        
        logger.info("✅ Demo results saved to ./demo_results/")

def main():
    """Main demo execution"""
    logger.info("🏭 Starting Smart Factory ML Demo...")
    
    try:
        # Initialize demo
        ml_demo = SmartFactoryMLDemo()
        
        # Generate demo data
        demo_data = ml_demo.generate_demo_data(samples=5000)
        
        # Train demo model
        model_results = ml_demo.train_demo_model(demo_data)
        
        # Generate business report
        business_report = ml_demo.generate_business_report(model_results, demo_data)
        
        # Combine results
        demo_results = {
            'timestamp': datetime.now().isoformat(),
            'workspace_info': {
                'subscription_id': ml_demo.subscription_id,
                'resource_group': ml_demo.resource_group,
                'workspace_name': ml_demo.workspace_name
            },
            'model_performance': {
                'accuracy': model_results['accuracy'],
                'feature_importance': model_results['feature_importance']
            },
            'business_impact': business_report['demo_metrics']
        }
        
        # Save results
        ml_demo.save_demo_results(demo_results)
        
        logger.info("🎉 Smart Factory ML Demo completed successfully!")
        logger.info(f"🎯 Model Accuracy: {model_results['accuracy']:.1%}")
        logger.info(f"💰 Predicted Annual Savings: ${business_report['demo_metrics']['predicted_savings_usd']:,.2f}")
        
        return demo_results
        
    except Exception as e:
        logger.error(f"❌ Demo failed: {e}")
        raise

if __name__ == "__main__":
    results = main()