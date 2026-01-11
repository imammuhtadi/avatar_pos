# Stage 1: Build Flutter web app
FROM ghcr.io/cirruslabs/flutter:stable AS build

# Build arguments for environment variables
ARG SUPABASE_URL
ARG SUPABASE_ANON_KEY

# Set working directory
WORKDIR /app

# Copy pubspec files
COPY pubspec.* ./

# Get dependencies
RUN flutter pub get

# Copy the rest of the application
COPY . .

# Create .env file with build arguments
RUN echo "SUPABASE_URL=${SUPABASE_URL}" > .env && \
    echo "SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}" >> .env

# Build web app
RUN flutter build web --release

# Stage 2: Serve with Nginx
FROM nginx:alpine

# Copy built web app to nginx
COPY --from=build /app/build/web /usr/share/nginx/html

# Copy custom nginx config (optional)
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
