import React from 'react';
import {AppRegistry} from 'react-native';
import SmartFactoryApp from './SmartFactoryApp';
import {name as appName} from './app.json';

// 📱 Main App Entry Point
AppRegistry.registerComponent(appName, () => SmartFactoryApp);