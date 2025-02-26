FROM busybox:stable
# Set non-root user for improved security
RUN adduser -D -u 1001 appuser

WORKDIR /app

# Copy initialization script and make it executable
COPY init.sh ./
RUN chmod +x ./init.sh && \
    chown appuser:appuser ./init.sh

# Add healthcheck
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD sh -c "test -f /app/data/.initialized || exit 1"

# Switch to non-root user
USER appuser