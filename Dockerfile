FROM python:3.11-slim

# System deps for playwright & llama-cpp
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install Python deps
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Install playwright browser
RUN playwright install chromium && playwright install-deps chromium

# Copy app
COPY . .

# Create models dir
RUN mkdir -p models

EXPOSE 8000

# The model will be downloaded on first run
CMD ["python", "-m", "app.main"]