# Smart Factory ML Training Report

## Training Summary
- **Date**: 2026-01-03T22:19:13.308766+00:00
- **Total Models**: 4
- **Successful Training**: 3
- **Azure ML Registrations**: 0

## Model Performance

### Production Optimization
- **mse**: 27.3511
- **rmse**: 5.2298
- **r2_score**: 0.8157
- **n_samples_train**: 8000
- **n_samples_test**: 2000

### Predictive Maintenance
- **accuracy**: 0.8450
- **anomaly_ratio**: 0.1695
- **n_samples_train**: 8000
- **n_samples_test**: 2000

### Quality Control
- **mse**: 4.1798
- **rmse**: 2.0445
- **r2_score**: 0.5659
- **n_samples_train**: 8000
- **n_samples_test**: 2000


## Registration Status

- **production_optimization**: ❌ Failed
- **predictive_maintenance**: ❌ Failed
- **quality_control**: ❌ Failed
- **energy_efficiency**: ❌ Failed


## Model Files

All trained models are saved in the `models_output` directory:

- **production_optimization**: `models_output\production-optimizer_model.joblib`
- **predictive_maintenance**: `models_output\predictive-maintenance_model.joblib`
- **quality_control**: `models_output\quality-controller_model.joblib`
