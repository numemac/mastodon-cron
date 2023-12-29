FROM auguryan/mastodon:latest

USER root

# install cron
RUN apt-get update && apt-get install -y cron

# run crontab in container using crontab file in this directory
COPY crontab /etc/cron.d/mastodon
RUN chmod 0644 /etc/cron.d/mastodon
RUN crontab /etc/cron.d/mastodon

# https://stackoverflow.com/a/62613296
RUN ln -s /usr/local/bin/ruby /usr/bin/ruby
RUN ln -s /usr/local/bin/bundle /usr/bin/bundle

# https://askubuntu.com/a/940321
ENV PATH="/usr/local/bin:${PATH}"

# forcefully remove /opt/mastodon/public dir if it exists so that a volume can be mounted here
RUN rm -rf /opt/mastodon/public

# run cron in foreground
CMD ["sh", "-c", "env >> /etc/environment && cron -f"]