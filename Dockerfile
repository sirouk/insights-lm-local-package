# Build stage
FROM node:22 as build

WORKDIR /app

# Add build arguments for environment variables
ARG VITE_SUPABASE_URL
ARG VITE_SUPABASE_ANON_KEY
ARG ENABLE_LIGHTRAG
ARG ENABLE_MULTIMODAL
ARG ENABLE_CONTEXTUAL

# Make build args available as environment variables during build
ENV VITE_SUPABASE_URL=${VITE_SUPABASE_URL}
ENV VITE_SUPABASE_ANON_KEY=${VITE_SUPABASE_ANON_KEY}
ENV VITE_ENABLE_LIGHTRAG=${ENABLE_LIGHTRAG}
ENV VITE_ENABLE_MULTIMODAL=${ENABLE_MULTIMODAL}
ENV VITE_ENABLE_CONTEXTUAL=${ENABLE_CONTEXTUAL}

# Clone the repository (into a temporary directory)
RUN apt-get update && apt-get install -y git && \
    git clone https://github.com/sirouk/insights-lm-public.git /tmp/repo && \
    # Clear the app directory before copying files
    rm -rf /app/* && \
    # Copy the repository contents to the app directory
    cp -r /tmp/repo/* /app/ && \
    # Attempt to copy hidden files, suppress errors if there are none
    cp -r /tmp/repo/.* /app/ 2>/dev/null || true && \
    # Clean up the temp directory
    rm -rf /tmp/repo

# Install and build
RUN npm install && \
    npm run build

# Production stage
FROM nginx:alpine

# Copy built files from the correct Vite output directory (dist)
COPY --from=build /app/dist /usr/share/nginx/html

# Configure nginx with Supabase proxy
RUN echo 'server { \
    listen 80; \
    location / { \
        root /usr/share/nginx/html; \
        try_files $uri $uri/ /index.html; \
    } \
}' > /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]