#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Smart Factory ML Training - Local Training with Cloud Registration

This script trains ML models locally on synthetic data and registers
them in Azure ML for cloud-native deployment and management.

Key Features:
- Trains 4 ML models locally (no Azure compute costs)
- Registers trained models to Azure ML Model Registry
- Generates synthetic training data
- Provides comprehensive model evaluation
- Cloud-native model management without compute overhead

Author: Smart Factory Team
Date: January 2026
"""

import os
import sys
import json
import logging
import tempfile
import numpy as np
import pandas as pd
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, Any, List, Tuple
from dataclasses import dataclass

# Azure ML SDK v2
from azure.ai.ml import MLClient
from azure.ai.ml.entities import Model
from azure.identity import DefaultAzureCredential

# ML Libraries
from sklearn.ensemble import RandomForestRegressor, IsolationForest, GradientBoostingRegressor
from sklearn.linear_model import LinearRegression
from sklearn.model_selection import train_test_split, GridSearchCV
from sklearn.metrics import mean_squared_error, r2_score, classification_report
from sklearn.preprocessing import StandardScaler
import joblib

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

@dataclass
class ModelConfig:
    """Configuration for ML models"""
    name: str
    description: str
    type: str
    hyperparameters: Dict[str, Any]
    features: List[str]

class SmartFactoryMLLocalTraining:
    """
    Smart Factory ML Training Pipeline
    Trains models locally and registers them to Azure ML
    """
    
    def __init__(self):
        self.ml_client = None
        self.models_dir = Path("models_output")
        self.models_dir.mkdir(exist_ok=True)
        
        # Model configurations
        self.model_configs = {
            "production_optimization": ModelConfig(
                name="production-optimizer",
                description="Optimizes production line efficiency based on sensor data",
                type="regression",
                hyperparameters={
                    'n_estimators': [100, 200, 300],
                    'max_depth': [10, 15, 20],
                    'min_samples_split': [2, 5, 10]
                },
                features=['temperature', 'humidity', 'vibration', 'pressure', 'speed']
            ),
            "predictive_maintenance": ModelConfig(
                name="predictive-maintenance",
                description="Predicts equipment maintenance needs using sensor patterns",
                type="classification",
                hyperparameters={
                    'contamination': [0.05, 0.1, 0.15],
                    'max_samples': [100, 'auto'],
                    'bootstrap': [True, False]
                },
                features=['temperature', 'vibration', 'pressure', 'runtime_hours', 'error_count']
            ),
            "quality_control": ModelConfig(
                name="quality-controller",
                description="Monitors product quality through real-time analytics",
                type="regression",
                hyperparameters={
                    'learning_rate': [0.05, 0.1, 0.2],
                    'n_estimators': [100, 200, 300],
                    'max_depth': [5, 7, 10]
                },
                features=['dimension_accuracy', 'surface_roughness', 'color_consistency', 'weight']
            ),
            "energy_efficiency": ModelConfig(
                name="energy-optimizer",
                description="Optimizes factory energy consumption patterns",
                type="regression",
                hyperparameters={
                    'fit_intercept': [True, False],
                    'positive': [True, False]
                },
                features=['power_consumption', 'production_rate', 'ambient_temp', 'machine_load']
            )
        }
        
        self.trained_models = {}
        self.model_metrics = {}
    
    def initialize_azure_ml(self) -> bool:
        """Initialize Azure ML client"""
        try:
            credential = DefaultAzureCredential()
            self.ml_client = MLClient(
                credential=credential,
                subscription_id="ab9fac11-f205-4caa-a081-9f71b839c5c0",
                resource_group_name="rg-smartfactory-prod",
                workspace_name="smartfactory-ml-prod"
            )
            logger.info("✅ Azure ML Client initialized successfully")
            return True
        except Exception as e:
            logger.error(f"❌ Failed to initialize Azure ML client: {str(e)}")
            return False
    
    def generate_synthetic_data(self, config: ModelConfig, n_samples: int = 10000) -> Tuple[pd.DataFrame, np.ndarray]:
        """Generate synthetic training data for each model"""
        logger.info(f"🔢 Generating {n_samples} synthetic samples for {config.name}")
        
        np.random.seed(42)  # For reproducible results
        
        # Generate feature data
        data = {}
        for feature in config.features:
            if feature == 'runtime_hours':
                data[feature] = np.random.exponential(100, n_samples)
            elif feature == 'error_count':
                data[feature] = np.random.poisson(2, n_samples)
            elif feature in ['temperature', 'pressure']:
                data[feature] = np.random.normal(50, 10, n_samples)
            elif feature in ['vibration', 'humidity']:
                data[feature] = np.random.normal(30, 8, n_samples)
            elif feature == 'speed':
                data[feature] = np.random.uniform(10, 100, n_samples)
            elif feature == 'dimension_accuracy':
                data[feature] = np.random.normal(99.5, 0.5, n_samples)
            elif feature == 'surface_roughness':
                data[feature] = np.random.exponential(2, n_samples)
            elif feature == 'color_consistency':
                data[feature] = np.random.beta(8, 2, n_samples) * 100
            elif feature == 'weight':
                data[feature] = np.random.normal(500, 50, n_samples)
            elif feature == 'power_consumption':
                data[feature] = np.random.gamma(2, 50, n_samples)
            elif feature == 'production_rate':
                data[feature] = np.random.uniform(50, 200, n_samples)
            elif feature == 'ambient_temp':
                data[feature] = np.random.normal(20, 5, n_samples)
            elif feature == 'machine_load':
                data[feature] = np.random.beta(5, 2, n_samples) * 100
            else:
                data[feature] = np.random.normal(0, 1, n_samples)
        
        df = pd.DataFrame(data)
        
        # Generate target variable based on model type
        if config.type == "regression":
            if config.name == "production-optimizer":
                target = (
                    df['temperature'].values * 0.3 +
                    df['pressure'].values * 0.2 +
                    df['speed'].values * 0.4 +
                    np.random.normal(0, 5, n_samples)
                )
            elif config.name == "quality-controller":
                target = (
                    df['dimension_accuracy'].values * 0.5 +
                    df['surface_roughness'].values * -0.3 +
                    df['color_consistency'].values * 0.2 +
                    np.random.normal(0, 2, n_samples)
                )
            elif config.name == "energy-optimizer":
                target = (
                    df['power_consumption'].values * 0.6 +
                    df['production_rate'].values * 0.3 +
                    df['machine_load'].values * 0.1 +
                    np.random.normal(0, 10, n_samples)
                )
            else:
                target = df[config.features[0]].values + np.random.normal(0, 1, n_samples)
        else:  # classification
            # For anomaly detection, create binary labels
            feature_mean = df[config.features].mean().mean()
            noise = np.random.normal(0, feature_mean * 0.1, n_samples)
            target = ((df[config.features].sum(axis=1) + noise) > df[config.features].sum(axis=1).quantile(0.9)).astype(int)
        
        return df, target
    
    def train_model(self, config: ModelConfig) -> Tuple[Any, Dict[str, float]]:
        """Train a single ML model"""
        logger.info(f"🚀 Training {config.name} model...")
        
        # Generate training data
        X, y = self.generate_synthetic_data(config)
        X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
        
        # Select model based on type
        if config.type == "regression":
            if config.name == "production-optimizer":
                model = RandomForestRegressor(random_state=42)
            elif config.name == "quality-controller":
                model = GradientBoostingRegressor(random_state=42)
            else:  # energy-optimizer
                model = LinearRegression()
        else:  # classification/anomaly detection
            model = IsolationForest(random_state=42)
            # For unsupervised model, only use X_train
            model.fit(X_train)
            predictions = model.predict(X_test)
            # Convert to binary classification metrics
            predictions_binary = (predictions == -1).astype(int)
            
            # Calculate metrics for anomaly detection
            accuracy = np.mean(predictions_binary == y_test)
            metrics = {
                "accuracy": accuracy,
                "anomaly_ratio": np.mean(predictions_binary),
                "n_samples_train": len(X_train),
                "n_samples_test": len(X_test)
            }
            
            return model, metrics
        
        # For supervised models, perform hyperparameter tuning
        if hasattr(model, 'get_params') and config.hyperparameters:
            logger.info(f"🎯 Performing hyperparameter tuning for {config.name}")
            grid_search = GridSearchCV(
                model, 
                config.hyperparameters, 
                cv=3, 
                scoring='neg_mean_squared_error' if config.type == "regression" else 'accuracy',
                n_jobs=-1
            )
            grid_search.fit(X_train, y_train)
            model = grid_search.best_estimator_
            logger.info(f"✅ Best parameters: {grid_search.best_params_}")
        else:
            model.fit(X_train, y_train)
        
        # Make predictions and calculate metrics
        predictions = model.predict(X_test)
        
        if config.type == "regression":
            mse = mean_squared_error(y_test, predictions)
            r2 = r2_score(y_test, predictions)
            rmse = np.sqrt(mse)
            metrics = {
                "mse": mse,
                "rmse": rmse,
                "r2_score": r2,
                "n_samples_train": len(X_train),
                "n_samples_test": len(X_test)
            }
        else:
            # For classification
            accuracy = np.mean(predictions == y_test)
            metrics = {
                "accuracy": accuracy,
                "n_samples_train": len(X_train),
                "n_samples_test": len(X_test)
            }
        
        logger.info(f"✅ {config.name} training completed. Metrics: {metrics}")
        return model, metrics
    
    def save_model_locally(self, model: Any, config: ModelConfig, metrics: Dict[str, float]) -> str:
        """Save trained model locally"""
        model_path = self.models_dir / f"{config.name}_model.joblib"
        metadata_path = self.models_dir / f"{config.name}_metadata.json"
        
        # Save model
        joblib.dump(model, model_path)
        
        # Save metadata
        metadata = {
            "model_name": config.name,
            "description": config.description,
            "type": config.type,
            "features": config.features,
            "metrics": metrics,
            "training_date": datetime.now(timezone.utc).isoformat(),
            "model_path": str(model_path)
        }
        
        with open(metadata_path, 'w', encoding='utf-8') as f:
            json.dump(metadata, f, indent=2, ensure_ascii=False)
        
        logger.info(f"💾 Model {config.name} saved locally at {model_path}")
        return str(model_path)
    
    def register_model_to_azure_ml(self, config: ModelConfig, model_path: str, metrics: Dict[str, float]) -> bool:
        """Register trained model to Azure ML"""
        try:
            if not self.ml_client:
                logger.error("❌ Azure ML client not initialized")
                return False
            
            logger.info(f"☁️ Registering {config.name} to Azure ML...")
            
            # Create model entity
            model_entity = Model(
                path=model_path,
                name=config.name,
                description=config.description,
                version=datetime.now().strftime("%Y%m%d_%H%M%S"),
                tags={
                    "type": config.type,
                    "features": ",".join(config.features),
                    "environment": "smart-factory",
                    "training_type": "local"
                },
                properties={
                    "training_date": datetime.now(timezone.utc).isoformat(),
                    **{f"metric_{k}": str(v) for k, v in metrics.items()}
                }
            )
            
            # Register model
            registered_model = self.ml_client.models.create_or_update(model_entity)
            logger.info(f"✅ Model {config.name} registered successfully: {registered_model.name}:{registered_model.version}")
            return True
            
        except Exception as e:
            logger.error(f"❌ Failed to register {config.name} to Azure ML: {str(e)}")
            return False
    
    def train_all_models(self) -> Dict[str, Any]:
        """Train all ML models"""
        logger.info("🏭 Starting Smart Factory ML Training Pipeline...")
        
        results = {
            "trained_models": {},
            "metrics": {},
            "registration_status": {},
            "summary": {
                "total_models": len(self.model_configs),
                "successful_training": 0,
                "successful_registration": 0,
                "training_start": datetime.now(timezone.utc).isoformat()
            }
        }
        
        for model_name, config in self.model_configs.items():
            try:
                # Train model
                logger.info(f"📊 Training {model_name}...")
                model, metrics = self.train_model(config)
                
                # Save locally
                model_path = self.save_model_locally(model, config, metrics)
                
                # Store results
                results["trained_models"][model_name] = model_path
                results["metrics"][model_name] = metrics
                results["summary"]["successful_training"] += 1
                
                # Register to Azure ML if client is available
                if self.ml_client:
                    registration_success = self.register_model_to_azure_ml(config, model_path, metrics)
                    results["registration_status"][model_name] = registration_success
                    if registration_success:
                        results["summary"]["successful_registration"] += 1
                else:
                    results["registration_status"][model_name] = False
                    logger.warning(f"⚠️ Skipping Azure ML registration for {model_name} - no ML client")
                
            except Exception as e:
                logger.error(f"❌ Failed to train {model_name}: {str(e)}")
                results["trained_models"][model_name] = None
                results["metrics"][model_name] = {"error": str(e)}
                results["registration_status"][model_name] = False
        
        results["summary"]["training_end"] = datetime.now(timezone.utc).isoformat()
        return results
    
    def generate_training_report(self, results: Dict[str, Any]) -> str:
        """Generate comprehensive training report"""
        report_path = self.models_dir / "training_report.md"
        
        report_content = f"""# Smart Factory ML Training Report

## Training Summary
- **Date**: {results['summary']['training_start']}
- **Total Models**: {results['summary']['total_models']}
- **Successful Training**: {results['summary']['successful_training']}
- **Azure ML Registrations**: {results['summary']['successful_registration']}

## Model Performance

"""
        
        for model_name, metrics in results["metrics"].items():
            if "error" not in metrics:
                report_content += f"### {model_name.replace('_', ' ').title()}\n"
                for metric, value in metrics.items():
                    if isinstance(value, float):
                        report_content += f"- **{metric}**: {value:.4f}\n"
                    else:
                        report_content += f"- **{metric}**: {value}\n"
                report_content += "\n"
        
        report_content += f"""
## Registration Status

"""
        for model_name, status in results["registration_status"].items():
            status_emoji = "✅" if status else "❌"
            report_content += f"- **{model_name}**: {status_emoji} {'Registered' if status else 'Failed'}\n"
        
        report_content += f"""

## Model Files

All trained models are saved in the `{self.models_dir}` directory:

"""
        for model_name, model_path in results["trained_models"].items():
            if model_path:
                report_content += f"- **{model_name}**: `{model_path}`\n"
        
        with open(report_path, 'w', encoding='utf-8') as f:
            f.write(report_content)
        
        logger.info(f"📄 Training report generated: {report_path}")
        return str(report_path)

def main() -> Dict[str, Any]:
    """Main execution function"""
    try:
        # Initialize ML pipeline
        ml_trainer = SmartFactoryMLLocalTraining()
        
        # Initialize Azure ML (optional - will work without it)
        azure_ml_available = ml_trainer.initialize_azure_ml()
        if not azure_ml_available:
            logger.warning("⚠️ Azure ML not available - models will be trained locally only")
        
        # Train all models
        results = ml_trainer.train_all_models()
        
        # Generate report
        report_path = ml_trainer.generate_training_report(results)
        results["report_path"] = report_path
        
        # Print summary
        print("\n" + "="*60)
        print("🏭 SMART FACTORY ML TRAINING COMPLETED")
        print("="*60)
        print(f"✅ Successfully trained: {results['summary']['successful_training']}/{results['summary']['total_models']} models")
        print(f"☁️ Azure ML registrations: {results['summary']['successful_registration']}/{results['summary']['total_models']} models")
        print(f"📄 Report generated: {report_path}")
        print(f"💾 Models saved in: {ml_trainer.models_dir}")
        print("="*60)
        
        return results
        
    except Exception as e:
        logger.error(f"❌ Pipeline failed: {str(e)}")
        raise

if __name__ == "__main__":
    results = main()