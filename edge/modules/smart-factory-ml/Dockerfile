FROM mcr.microsoft.com/azureml/onnxruntime:latest

# Set working directory
WORKDIR /app

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Expose port
EXPOSE 5000

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV INFERENCE_MODE=edge

# Run the application
CMD ["python", "main.py"]