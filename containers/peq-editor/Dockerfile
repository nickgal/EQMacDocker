FROM php:8.3-apache

RUN docker-php-ext-install mysqli

# The editor uses short open tags and relies on .htaccess to block direct
# access to every script except its entry points.
# PHP warnings from the editor go to the container log instead of the page.
RUN printf 'short_open_tag = On\ndisplay_errors = Off\nlog_errors = On\nerror_log = /dev/stderr\n' \
        > /usr/local/etc/php/conf.d/peq-editor.ini && \
    sed -i '/<Directory \/var\/www\/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf

COPY --from=ghcr.io/ufoscout/docker-compose-wait:latest /wait /wait

ADD PEQEditor /var/www/html
RUN rm -rf /var/www/html/.git /var/www/html/dev /var/www/html/AutoUpdate && \
    # config.php's env() reads "0" as unset, so GUEST_MODE_ENABLE=0 cannot turn
    # off the passwordless guest login. Default it to off instead.
    sed -e 's|^\$quest_path = .*|$quest_path = "/quests";|' \
        -e "s|env('GUEST_MODE_ENABLE', 1)|env('GUEST_MODE_ENABLE', 0)|" \
        /var/www/html/config.php.dist > /var/www/html/config.php && \
    mkdir -p /var/www/html/logs && \
    chown -R www-data:www-data /var/www/html/logs

ADD Quests /quests

ADD containers/peq-editor/init_admin.php /init_admin.php
ADD containers/peq-editor/docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT [ "/docker-entrypoint.sh" ]
CMD [ "apache2-foreground" ]
