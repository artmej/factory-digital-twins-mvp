// Smart Factory - Domain Models
// Core business logic and entities

export interface Machine {
  machineId: string;
  lineId: string;
  type: MachineType;
  status: OperationalStatus;
  location: Location;
  sensors: Sensor[];
  maintenanceSchedule: MaintenanceSchedule;
  specifications: MachineSpecifications;
  createdAt: Date;
  updatedAt: Date;
}

export interface Sensor {
  sensorId: string;
  machineId: string;
  type: SensorType;
  value: number;
  unit: string;
  timestamp: Date;
  quality: QualityIndicator;
  thresholds: SensorThresholds;
}

export interface ProductionLine {
  lineId: string;
  facilityId: string;
  name: string;
  machines: Machine[];
  targetOEE: number;
  currentOEE: OEEMetrics;
  shift: ShiftSchedule;
  status: LineStatus;
}

export interface Alert {
  alertId: string;
  machineId: string;
  type: AlertType;
  severity: AlertSeverity;
  message: string;
  timestamp: Date;
  acknowledged: boolean;
  acknowledgedBy?: string;
  resolvedAt?: Date;
  mlPrediction?: MLPrediction;
}

export interface OEEMetrics {
  availability: number;
  performance: number;
  quality: number;
  overall: number;
  calculatedAt: Date;
  period: TimePeriod;
}

// Enums and Types
export enum MachineType {
  CNC_MILLING = 'cnc-milling',
  ROBOTIC_ARM = 'robotic-arm',
  ASSEMBLY_LINE = 'assembly-line',
  QUALITY_CONTROL = 'quality-control',
  PACKAGING = 'packaging'
}

export enum OperationalStatus {
  OPERATIONAL = 'operational',
  WARNING = 'warning',
  CRITICAL = 'critical',
  MAINTENANCE = 'maintenance',
  OFFLINE = 'offline'
}

export enum SensorType {
  TEMPERATURE = 'temperature',
  VIBRATION = 'vibration',
  PRESSURE = 'pressure',
  HUMIDITY = 'humidity',
  POWER_CONSUMPTION = 'power-consumption',
  ROTATION_SPEED = 'rotation-speed',
  CYCLE_COUNT = 'cycle-count'
}

export enum QualityIndicator {
  GOOD = 'good',
  UNCERTAIN = 'uncertain',
  BAD = 'bad'
}

export enum AlertType {
  ANOMALY_DETECTION = 'anomaly-detection',
  THRESHOLD_VIOLATION = 'threshold-violation',
  PREDICTIVE_MAINTENANCE = 'predictive-maintenance',
  SYSTEM_FAILURE = 'system-failure',
  QUALITY_ISSUE = 'quality-issue'
}

export enum AlertSeverity {
  INFO = 'info',
  WARNING = 'warning',
  CRITICAL = 'critical',
  EMERGENCY = 'emergency'
}

// Value Objects
export interface Location {
  facilityId: string;
  floor: string;
  zone: string;
  coordinates: {
    x: number;
    y: number;
    z?: number;
  };
}

export interface SensorThresholds {
  min: number;
  max: number;
  warningLow: number;
  warningHigh: number;
}

export interface MaintenanceSchedule {
  type: 'preventive' | 'predictive';
  interval: number; // hours
  lastMaintenance: Date;
  nextMaintenance: Date;
  estimatedDuration: number; // hours
}

export interface MachineSpecifications {
  manufacturer: string;
  model: string;
  yearInstalled: number;
  maxCapacity: number;
  powerRating: number; // kW
  dimensions: {
    length: number;
    width: number;
    height: number;
  };
}

export interface MLPrediction {
  predictionId: string;
  model: string;
  version: string;
  confidence: number;
  prediction: any;
  features: Record<string, number>;
  timestamp: Date;
}

export interface ShiftSchedule {
  shiftId: string;
  name: string;
  startTime: string; // HH:mm format
  endTime: string;
  weekdays: number[]; // 0-6, Sunday=0
}

export interface TimePeriod {
  start: Date;
  end: Date;
  duration: number; // milliseconds
}