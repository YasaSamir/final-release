FROM debian:latest AS build-env

# Install flutter dependencies
RUN apt-get update && \
    apt-get install -y curl git unzip xz-utils zip libglu1-mesa && \
    apt-get clean

# Clone the flutter repo
RUN git clone https://github.com/flutter/flutter.git /usr/local/flutter

# Set flutter path
ENV PATH="${PATH}:/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin"

# Run flutter doctor
RUN flutter doctor

# Enable web
RUN flutter channel stable && \
    flutter upgrade && \
    flutter config --enable-web

# Copy files to container and build
WORKDIR /app
COPY . .
RUN flutter pub get
RUN flutter build web

# Stage 2 - Create the run-time image
FROM nginx:1.21.1-alpine
COPY --from=build-env /app/build/web /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
