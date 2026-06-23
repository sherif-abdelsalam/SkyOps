# Use the official Go image only for compiling the application.
# This stage contains build tools that we do not want in the final image.
FROM golang:1.22-alpine AS builder

WORKDIR /app

# Copy dependency files first.
# This allows Docker to reuse the cached "go mod download" layer
# if the source code changes but dependencies remain the same.
COPY go.mod go.sum ./

RUN go mod download

COPY . .

# Build a statically linked Linux binary
# CGO_ENABLED=0 removes dependency on C libraries
# -w -s strips debug information to reduce binary size
RUN CGO_ENABLED=0 GOOS=linux go build \
    -ldflags="-w -s" \
    -o /app/bin/app \
    ./main

# Use Google's Distroless image for production.
# Distroless images contain only the application runtime
# and remove shells, package managers, and other utilities,
# reducing image size and attack surface.
FROM gcr.io/distroless/static:nonroot

# Copy only the compiled binary from the builder stage.
# No source code or build tools are included in the final image.
COPY --from=builder /app/bin/app /app

EXPOSE 8080

# Run as a non-root user.
# The ':nonroot' variant already provides a low-privilege user,
# which is a container security best practice.
ENTRYPOINT ["/app"]