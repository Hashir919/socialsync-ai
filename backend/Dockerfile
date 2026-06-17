# Use official lightweight Python image
FROM python:3.10-slim

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PORT=8000

# Set working directory inside the container
WORKDIR /app

# Install system dependencies (needed for some Python libraries)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements file first for caching
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the backend files
COPY . /app/backend

# Copy scripts folder since it is referenced in sys.path
COPY ../scripts /app/scripts
COPY ../socialsync_dataset.json /app/

# Set working directory to backend
WORKDIR /app/backend

# Expose port
EXPOSE 8000

# Start FastAPI with Uvicorn, dynamically using PORT environment variable
CMD uvicorn main:app --host 0.0.0.0 --port ${PORT}
