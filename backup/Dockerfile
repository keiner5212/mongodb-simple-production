FROM mongo:7.0

RUN apt-get update \
    && apt-get install -y --no-install-recommends bash ca-certificates tzdata \
    && rm -rf /var/lib/apt/lists/*

COPY backup.sh /usr/local/bin/backup.sh
# Strip Windows CRLF if file edited on Windows
RUN sed -i 's/\r$//' /usr/local/bin/backup.sh \
    && chmod +x /usr/local/bin/backup.sh

ENV BACKUP_PATH=/backup \
    BACKUP_INTERVAL_HOURS=24 \
    BACKUP_MAX_COUNT=14

ENTRYPOINT ["/usr/local/bin/backup.sh"]
