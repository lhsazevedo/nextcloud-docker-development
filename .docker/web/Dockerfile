FROM nginx:alpine

RUN addgroup --gid 1000 --system nextcloud \
    && adduser --system --uid 1000 --ingroup nextcloud nextcloud

COPY nginx.conf /etc/nginx/nginx.conf
