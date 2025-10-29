# Use a small Python base image
FROM python:3.11-slim

# Set the working directory inside the container
WORKDIR /app

# Copy dependency list first (for caching)
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy your Python script
COPY temp_control.py .

# Run the script by default
CMD ["python", "temp_control.py"]