FROM python:3.10-slim-bookworm

# install uv
COPY --from=ghcr.io/astral-sh/uv:0.6.14 /uv /uvx /bin/

# Create a non-root user
RUN useradd -m -u 1000 appuser && \
    mkdir -p /app && \
    chown -R appuser:appuser /app

WORKDIR /app

# Install system dependencies
RUN apt-get update -y && \
    apt-get install --no-install-recommends -y clang ca-certificates git && \
    rm -rf /var/lib/apt/lists/*

# Copy the project and set permissions
COPY . /app
RUN chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Install Python dependencies
RUN uv sync --frozen --no-dev

# Switch back to root for system operations
USER root

# VNC password will be read from Docker secrets or fallback to default
# Create a fallback default password file
RUN mkdir -p /run/secrets && \
    echo "browser-use" > /run/secrets/vnc_password_default

# Install required packages including Chromium and clean up in the same layer
RUN apt-get update && \
    apt-get install --no-install-recommends -y \
    xfce4 \
    xfce4-terminal \
    dbus-x11 \
    tigervnc-standalone-server \
    tigervnc-tools \
    nodejs \
    npm \
    fonts-freefont-ttf \
    fonts-ipafont-gothic \
    fonts-wqy-zenhei \
    fonts-thai-tlwg \
    fonts-kacst \
    fonts-symbola \
    fonts-noto-color-emoji && \
    npm i -g proxy-login-automator && \
    apt-get remove --purge -y git && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/cache/apt/*

ENV ANONYMIZED_TELEMETRY=false \
    PATH="/app/.venv/bin:$PATH" \
    DISPLAY=:0 \
    CHROME_BIN=/usr/bin/chromium \
    CHROMIUM_FLAGS="--no-sandbox --headless --disable-gpu --disable-software-rasterizer --disable-dev-shm-usage" \
    PLAYWRIGHT_BROWSERS_PATH=/usr/share/ms-playwright

# Create necessary directories with proper permissions
RUN mkdir -p /tmp/.X11-unix && \
    chmod 1777 /tmp/.X11-unix

# Combine VNC setup commands to reduce layers
RUN mkdir -p /app/.vnc && \
    printf '#!/bin/sh\nunset SESSION_MANAGER\nunset DBUS_SESSION_BUS_ADDRESS\nstartxfce4' > /app/.vnc/xstartup && \
    chmod +x /app/.vnc/xstartup && \
    printf '#!/bin/bash\n\n# Use Docker secret for VNC password if available, else fallback to default\nif [ -f "/run/secrets/vnc_password" ]; then\n  cat /run/secrets/vnc_password | vncpasswd -f > /app/.vnc/passwd\nelse\n  cat /run/secrets/vnc_password_default | vncpasswd -f > /app/.vnc/passwd\nfi\n\nchmod 600 /app/.vnc/passwd\nvncserver -depth 24 -geometry 1920x1080 -localhost no -PasswordFile /app/.vnc/passwd :0\nproxy-login-automator\npython /app/server --port 8002' > /app/boot.sh && \
    chmod +x /app/boot.sh && \
    chown -R appuser:appuser /app/.vnc

RUN mkdir -p /usr/share/ms-playwright && \
    playwright install --with-deps --no-shell chromium && \
    chown -R appuser:appuser /usr/share/ms-playwright

USER appuser

EXPOSE 8002

ENTRYPOINT ["/bin/bash", "/app/boot.sh"]