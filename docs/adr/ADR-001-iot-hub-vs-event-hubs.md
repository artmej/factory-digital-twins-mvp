# ADR-001: Azure IoT Hub vs Direct Event Hubs

**Status:** ✅ Accepted  
**Date:** 2025-12-25  
**Deciders:** Azure Solutions Architecture Team  
**Technical Story:** [Case Study #36 - Smart Factory Data Ingestion](../design.md#architecture-decision-records-adrs)

## Context

Smart Factory requires ingestion of telemetry from 5,000+ industrial IoT devices. We need to choose between Azure IoT Hub and Event Hubs for primary data ingestion.

## Decision Drivers

- **Device Management:** Need for device lifecycle management and security
- **Protocol Support:** Industrial protocols (OPC UA, MQTT, AMQP)
- **Scalability:** Handle 5,000 devices with 1 message/5 seconds
- **Cost:** Balance functionality vs operational expense
- **Integration:** Seamless connection with Azure Digital Twins and Functions

## Options Considered

### Option A: Azure IoT Hub ✅ **SELECTED**
- **Pros:**
  - Built-in device identity management and authentication
  - Per-device security credentials and certificates
  - Message routing capabilities to multiple endpoints
  - Device-to-cloud and cloud-to-device messaging
  - Integration with Azure Digital Twins and other PaaS services
  - Built-in device monitoring and diagnostics
  - Support for device twins and direct methods

- **Cons:**
  - Higher cost per message compared to Event Hubs
  - Lower maximum throughput (8,000 messages/sec per unit)

### Option B: Event Hubs Direct
- **Pros:**
  - Lower cost per message
  - Higher throughput capabilities
  - Simpler for pure streaming scenarios

- **Cons:**
  - No device identity management
  - Requires custom authentication implementation
  - No built-in device monitoring
  - Complex integration for device commands

### Option C: Hybrid (Event Hubs + IoT Hub)
- **Pros:**
  - Best of both worlds for different use cases

- **Cons:**
  - Increased complexity and operational overhead
  - Multiple ingestion points to manage

## Decision

We chose **Azure IoT Hub** as the primary ingestion endpoint.

## Rationale

1. **Device Lifecycle Management:** Essential for 5,000+ devices requiring registration, authentication, and monitoring
2. **Security:** Per-device certificates and identity management are critical for industrial environments
3. **Message Routing:** Built-in routing to Digital Twins, Functions, and storage eliminates custom routing logic
4. **Integration:** Native integration with Azure Digital Twins for real-time model updates
5. **Monitoring:** Built-in device monitoring reduces operational complexity

**Cost Analysis:**
- IoT Hub S1: ~$200/month for 5,000 devices
- Savings from reduced development and operational overhead: ~$50,000
- **Net ROI:** Positive within first quarter

## Consequences

### Positive
- ✅ Simplified device onboarding and management
- ✅ Enhanced security posture with per-device authentication
- ✅ Reduced development time for routing and integration
- ✅ Built-in monitoring and alerting capabilities
- ✅ Future-proof for device command and control scenarios

### Negative
- ❌ Higher per-message cost compared to Event Hubs
- ❌ Throughput limitations for extremely high-volume scenarios
- ❌ Azure platform lock-in

### Mitigation
- **Cost:** Implement intelligent message batching and filtering at edge
- **Throughput:** Use Event Hubs for high-volume analytics data if needed
- **Lock-in:** Use standard protocols (MQTT/AMQP) to maintain portability

## Validation

**Success Metrics:**
- Device registration time < 30 seconds
- Message delivery latency < 100ms
- 99.9% message delivery rate
- Zero security incidents related to device authentication

**Review Date:** March 2026