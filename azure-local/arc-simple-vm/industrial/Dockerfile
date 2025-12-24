# Dockerfile for Factory Simulator as IoT Edge Module
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Add metadata
LABEL maintainer="Factory Digital Twins Team"
LABEL description="IoT Edge module for factory telemetry simulation"
LABEL version="1.0"

# Install dependencies first (for better caching)
COPY package*.json ./
RUN npm ci --only=production && \
    npm cache clean --force && \
    rm -rf /tmp/*

# Copy application code
COPY . .

# Create non-root user for security
RUN addgroup -g 1001 -S nodeuser && \
    adduser -S nodeuser -u 1001 -G nodeuser && \
    chown -R nodeuser:nodeuser /app

# Switch to non-root user
USER nodeuser

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD node -e "console.log('Health check passed')" || exit 1

# Expose port (if needed for debugging/monitoring)
EXPOSE 8080

# Start the simulator
CMD ["node", "simulator.js"]