# ADR-002: Azure Functions vs Container Apps for Event Processing

**Status:** ✅ Accepted  
**Date:** 2025-12-25  
**Deciders:** Azure Solutions Architecture Team  
**Technical Story:** [Case Study #36 - Smart Factory Event Processing](../design.md#event-driven-architecture-pub-sub)

## Context

Smart Factory needs real-time processing of IoT telemetry data from Azure IoT Hub. Processing includes data transformation, enrichment, validation, and routing to Azure Digital Twins. We need to choose the optimal compute platform.

## Decision Drivers

- **Event-driven Workloads:** React to IoT Hub messages in real-time
- **Scalability:** Auto-scale based on message volume (1,000-3,000 msg/sec)
- **Cost Efficiency:** Pay-per-execution model preferred
- **Development Velocity:** Rapid development and deployment
- **Cold Start Tolerance:** Acceptable for non-critical processing
- **Integration:** Native Azure service integration

## Options Considered

### Option A: Azure Functions (Consumption Plan) ✅ **SELECTED**
- **Pros:**
  - True serverless with pay-per-execution pricing
  - Native IoT Hub triggers and bindings
  - Automatic scaling based on queue depth
  - Built-in retry policies and dead letter queues
  - Minimal operational overhead
  - Excellent for event-driven architectures

- **Cons:**
  - Cold start latency (2-3 seconds)
  - Execution time limits (10 minutes max)
  - Limited control over runtime environment

### Option B: Azure Container Apps
- **Pros:**
  - Consistent runtime environment
  - No cold start issues
  - Support for long-running processes
  - Kubernetes-based with advanced scheduling

- **Cons:**
  - More complex setup and configuration
  - Always-on pricing model
  - Requires custom event polling implementation
  - Higher operational complexity

### Option C: Azure Functions (Premium Plan)
- **Pros:**
  - Eliminates cold start with pre-warmed instances
  - Better performance consistency
  - VNet integration capabilities

- **Cons:**
  - Higher cost with always-on pricing
  - Reduced cost efficiency benefit

## Decision

We chose **Azure Functions with Consumption Plan** for event processing.

## Rationale

1. **Event-Driven Architecture:** Perfect fit for reactive IoT telemetry processing
2. **Cost Model:** Pay-per-execution aligns with variable IoT message patterns
3. **Native Integration:** Built-in IoT Hub triggers eliminate custom polling logic
4. **Auto-scaling:** Automatically handles traffic spikes during shift changes
5. **Development Efficiency:** Reduced boilerplate code for event handling

**Performance Analysis:**
- Cold start acceptable for telemetry processing (non-critical path)
- Processing time: 50-200ms (well within limits)
- Scaling: 200 concurrent executions handle peak load
- Cost: ~$150/month vs ~$800/month for Container Apps

## Consequences

### Positive
- ✅ Minimal operational overhead and infrastructure management
- ✅ Cost-efficient with automatic scaling to zero
- ✅ Native Azure ecosystem integration
- ✅ Built-in monitoring with Application Insights
- ✅ Rapid development and deployment cycles
- ✅ Automatic retry and error handling

### Negative
- ❌ Cold start latency for first requests after idle periods
- ❌ Execution time limits for long-running tasks
- ❌ Limited runtime environment customization
- ❌ Potential throttling under extreme load

### Mitigation Strategies
- **Cold Start:** Keep functions warm with health check timer triggers
- **Time Limits:** Break down large processing tasks into smaller functions
- **Throttling:** Implement queue-based load leveling with Service Bus
- **Monitoring:** Enhanced monitoring for cold start patterns and optimization

## Implementation Details

### Function Architecture
```
IoT Hub → Event Hub Trigger → Function App → Digital Twins
                           ↓
                     Service Bus Queue → Batch Processing Function
```

### Key Functions
- **TelemetryProcessor:** Real-time telemetry transformation
- **DigitalTwinUpdater:** Azure Digital Twins synchronization
- **AlertProcessor:** Anomaly detection and alert generation
- **BatchProcessor:** Batch analytics and reporting

## Validation

**Success Metrics:**
- Processing latency < 500ms (95th percentile)
- Function execution success rate > 99.9%
- Cost per message < $0.001
- Auto-scaling responsiveness < 30 seconds

**Performance Benchmarks:**
- Peak throughput: 3,000 messages/second
- Concurrent executions: 200
- Average processing time: 150ms
- Cold start frequency: < 5% of executions

**Review Date:** March 2026

## Related Decisions
- [ADR-003: Event-driven vs Request-Response Patterns](ADR-003-event-driven-patterns.md)
- [ADR-005: VNet Integration for Security](ADR-005-vnet-integration.md)