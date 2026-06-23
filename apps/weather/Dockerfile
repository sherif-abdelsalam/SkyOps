FROM python:3.12-slim AS builder
WORKDIR /app
COPY requirements.txt .


# --no-cache-dir prevents pip from storing downloaded packages
# inside the image, reducing image size and improving security.
# --prefix=/install isolates packages so we can copy only them
# into the final image, leaving pip and build tools behind.
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

FROM python:3.12-slim
WORKDIR /app

# Create a non-root user before copying files.
# Running containers as root is not recommended in production
# because an attacker who compromises the application would
# gain root privileges inside the container.
RUN useradd -m appuser

# Copy only the installed packages from the builder stage.
# No pip, no build tools, no cache — just the runtime dependencies.
COPY --from=builder /install /usr/local

# Copy application source code.
COPY . .

# Transfer ownership of all app files to the non-root user.
# Without this, files copied as root would be unreadable
# or unwritable by appuser at runtime.
RUN chown -R appuser:appuser /app

# Switch to the non-root user for all subsequent commands.
USER appuser

EXPOSE 5000
CMD ["python", "main.py"]