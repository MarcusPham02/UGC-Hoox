# Stage 1: Build Flutter web app
FROM ghcr.io/cirruslabs/flutter:stable AS build
WORKDIR /app
COPY . .
RUN flutter pub get
RUN flutter build web --release --dart-define-from-file=.env.json

# Stage 2: Serve with nginx
FROM nginx:alpine
RUN sed -i 's/^user  nginx;/# user  nginx;/' /etc/nginx/nginx.conf && \
    mkdir -p /var/cache/nginx/client_temp /var/cache/nginx/proxy_temp /var/cache/nginx/fastcgi_temp /var/cache/nginx/uwsgi_temp /var/cache/nginx/scgi_temp && \
    chown -R nginx:nginx /var/cache/nginx /var/run /etc/nginx/conf.d
COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
USER nginx
