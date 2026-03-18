# WebArena Benchmark Docker Image
FROM python:3.10-bookworm

# Install system dependencies for playwright and chromium
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    gnupg \
    libnss3 \
    libnspr4 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libxkbcommon0 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxrandr2 \
    libgbm1 \
    libasound2 \
    libpango-1.0-0 \
    libcairo2 \
    libatspi2.0-0 \
    libgtk-3-0 \
    fonts-liberation \
    fonts-unifont \
    xdg-utils \
    libx11-xcb1 \
    libxcb-dri3-0 \
    libxshmfence1 \
    libglu1-mesa \
    xvfb \
    libxss1 \
    libxtst6 \
    libgconf-2-4 \
    libxi6 \
    && rm -rf /var/lib/apt/lists/*

# Install uv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:$PATH"

# Set working directory
WORKDIR /app

# Copy requirements first for better caching
COPY requirements.txt .

# Create virtual environment with uv
RUN uv venv .venv

# Activate venv for all subsequent commands
ENV VIRTUAL_ENV=/app/.venv
ENV PATH="/app/.venv/bin:$PATH"

# Install dependencies with uv
RUN uv pip install -r requirements.txt

# Install playwright and browsers
RUN uv pip install playwright && playwright install chromium

# Install NLTK data
RUN python -m nltk.downloader punkt stopwords punkt_tab

# Copy the rest of the application
COPY . .

# Install the package in editable mode
RUN uv pip install -e .

# Create directories for auth and results
RUN mkdir -p .auth log_files cache/results

# Set environment variables (overridden by docker-compose)
ENV SHOPPING="http://shopping:80"
ENV SHOPPING_ADMIN="http://shopping_admin:80/admin"
ENV REDDIT="http://forum:80"
ENV GITLAB="http://gitlab:8023"
ENV MAP="http://map:3000"
ENV WIKIPEDIA="http://wikipedia:80/wikipedia_en_all_maxi_2022-05/A/User:The_other_Kiwix_guy/Landing"
ENV HOMEPAGE="PASS"

# Default command
CMD ["python", "run.py", "--help"]
