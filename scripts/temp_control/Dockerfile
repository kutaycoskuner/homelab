# Use a small Python base image
FROM python:3.11-slim@sha256:673719e071ecf27434fd2635bbd8d00f49f4fdd81f243143438a42ced8bedf60

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