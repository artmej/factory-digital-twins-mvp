# Project Structure

## Directory Organization

```
smart-factory/
├── azure-cloud/          # ☁️ Azure Cloud Components
│   ├── digital-twins/    # DTDL models for factory representation
│   ├── iot-hub/         # Device connectivity configuration  
│   └── functions/       # Serverless data processing
│
├── azure-local/         # 🏭 On-Premise Components
│   ├── factory-simulator/ # Industrial device simulation
│   └── arc-simple-vm/   # Azure Arc connected VM config
│
├── applications/        # 📱 User Applications
│   ├── mobile-app/      # React Native factory worker app
│   └── web-dashboard/   # Progressive web app for engineers
│
├── infrastructure/      # 🔧 Infrastructure as Code
│   ├── bicep/          # Azure resource deployment templates
│   └── scripts/        # Automation and utility scripts
│
├── docs/               # 📖 Documentation
│   ├── architecture/   # Technical architecture diagrams
│   └── GETTING-STARTED.md # Quick start guide
│
├── tests/              # 🧪 Testing
│   ├── unit/          # Unit tests for components
│   └── integration/   # End-to-end integration tests
│
└── logs/              # 📋 Application Logs
    ├── factory/       # Factory simulator logs
    └── deployment/    # Infrastructure deployment logs
```

## File Purpose

### Root Files
- **README.md**: Main project documentation and overview
- **package.json**: Node.js dependencies and scripts  
- **LICENSE**: MIT license for open source usage
- **.gitignore**: Git ignore patterns for clean repository

### Configuration
- **eslint.config.js**: Code linting and style rules
- **.github/**: GitHub Actions CI/CD workflows

## Development Workflow

1. **Infrastructure**: Deploy Azure resources using `infrastructure/bicep/`
2. **Azure Local**: Setup on-premise components in `azure-local/`  
3. **Applications**: Build and deploy apps from `applications/`
4. **Testing**: Run tests from `tests/` directory
5. **Documentation**: Update docs in `docs/` as needed

## Cleanup Notes

- **temp-cleanup/**: Contains moved configuration files from restructuring
- **node_modules/**: NPM dependencies (auto-generated)
- **.venv/**: Python virtual environment (auto-generated)
- **logs/**: Runtime logs (auto-generated)

These directories can be excluded from version control and are regenerated as needed.