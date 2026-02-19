# ---------- Build stage ----------
FROM python:3.11-alpine AS builder

# Build deps needed for compiling wheels (uWSGI, etc.)
RUN apk add --no-cache linux-headers build-base

WORKDIR /install

# Install Python deps into a relocatable prefix we can copy later
COPY requirements.txt /requirements.txt
RUN pip install --no-cache-dir --upgrade pip \
 && pip install --no-cache-dir --prefix=/install -r /requirements.txt

# ---------- Runtime stage ----------
FROM python:3.11-alpine

# Create non-root user
RUN adduser -D dummyuser

# Copy site-packages and scripts from builder
COPY --from=builder /install /usr/local

# Workdir + app code
WORKDIR /app
COPY . /app

# Ownership for runtime writes (e.g., sqlite, logs)
RUN chown -R dummyuser:dummyuser /app
USER dummyuser

# If your app truly needs a pre-created sqlite file, keep this line; else remove it.
# RUN touch database.db

EXPOSE 8080

# IMPORTANT: Your conf.ini must exist at /app/conf.ini and point to the correct module
# Example conf.ini:
# [uwsgi]
# module = app:app
# master = true
# processes = 2
# threads = 4
# http-socket = 0.0.0.0:8080
# vacuum = true
# die-on-term = true

CMD ["uwsgi", "--ini", "/app/conf.ini"]
``
