# Base image with Java and Android SDK pre-installed
FROM ghcr.io/cirruslabs/flutter:3.29.0

# Set environment variables
ENV ANDROID_HOME="/opt/android-sdk"
ENV PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"

# Install additional dependencies
RUN apt-get update && apt-get install -y \
    unzip \
    wget \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Android SDK components
RUN yes | sdkmanager "platform-tools" "platforms;android-35" "build-tools;35.0.1"

# Set working directory
WORKDIR /app

# Copy the Flutter project into the container
COPY . .

# Pre-cache Flutter dependencies
RUN flutter pub get

# Build the APK (optional)
# RUN flutter build apk

# Default command to open a shell
CMD ["bash"]