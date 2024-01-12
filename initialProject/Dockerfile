FROM ghcr.io/filbe/diploi-tgbot-template:main

# Install application code
WORKDIR /app
COPY . .
RUN npm install
RUN npm run build

# Ensure that telegram bot will have its sqlite3 file available during the start
RUN touch tgbot.db

# This is the project level supervisor config that includes only in-project configs
# All Diploi-level dependent configs are in template level, so you could just rely on it
# Feel free to add your own supervisor processes in this file!
COPY supervisord.conf /etc/supervisord-tgbot.conf

# this is the main supervisord.conf that includes /etc/supervisord-*.conf in it.
# reload the values
CMD /usr/bin/supervisord -c /etc/supervisord.conf