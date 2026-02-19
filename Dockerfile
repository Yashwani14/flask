# ---------- Build stage (compile uwsgi wheels, etc.) ----------
FROM python:3.11-alpine AS builder

# uWSGI build deps (C compiler, headers)
RUN apk add --no-cache linux-headers build-base

WORKDIR /install

# Copy just requirements first to leverage layer caching
COPY requirements.txt /requirements.txt
RUN pip install --no-cache-dir --upgrade pip \
 && pip install --no-cache-dir --prefix=/install -r /requirements.txt

# ---------- Runtime stage (slim) ----------
FROM python:3.11-alpine

# Copy wheels/site-packages from builder
COPY --from=builder /install /usr/local

# Create a non-root user
RUN adduser -D dummyuser

# Create app dir and copy the entire repo content (since app.py, conf.ini, setup.py are at root)
WORKDIR /app
COPY . /app

# Ensure the non-root user owns the working dir (sqlite writes, etc.)
RUN chown -R dummyuser:dummyuser /app
USER dummyuser

# Initialize sqlite DB once (your setup.py should handle idempotency)
# If setup.py creates/updates database.db, keep this line;
# otherwise, you can remove both RUN lines below.
RUN touch database.db
RUN python ./setup.py

EXPOSE 8080

# conf.ini is at /app/conf.ini (copied above), so point uwsgi to it explicitly
CMD ["uwsgi", "--ini", "/app/conf.ini"]
