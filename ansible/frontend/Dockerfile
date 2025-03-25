FROM php:8.4-apache
ENV APP_CONFIG='{"esUrl": "http://localhost:9001", "index": "index000", "predefinedFields": ["title", "description"], "defaultSortField": "@timestamp"}'

RUN echo SetEnv APP_CONFIG "'"$APP_CONFIG"'" >> /etc/apache2/conf-enabled/environment.conf

COPY ./public-html/ /var/www/html/
