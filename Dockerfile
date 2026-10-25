FROM golang:1.27.3-alpine AS builder

# ensure the go install directory is in the PATH
ARG GOBIN=/usr/local/bin/
# ensure the golangci-lint install directory is in the PATH
ARG BINDIR=/usr/local/bin/
# ensure the bun install directory is in the PATH
ENV BUN_INSTALL=/usr/local

# Install dependencies and tools
RUN apk --no-cache add --virtual .build-deps \
        npm curl \
    && go install github.com/go-task/task/v3/cmd/task@main \
    && curl -sSfL https://golangci-lint.run/install.sh -o /tmp/install.sh \
    && chmod +x /tmp/install.sh \
    && /tmp/install.sh v2.14.0 \
    && apk del .build-deps \
    && rm -rf /tmp/* /var/cache/apk/*

# Copy tools from other images
COPY --from=buildkite/agent:4.3 /usr/local/bin/buildkite-agent /bin/buildkite-agent

# Final stage
FROM golang:1.27.3-alpine

RUN apk --no-cache add \
		gcc musl-dev curl jq git npm github-cli bash openssh-client

# Copy only necessary files from the builder stage
COPY --from=builder /bin/buildkite-agent /bin/buildkite-agent
COPY --from=builder /usr/local/bin /usr/local/bin

RUN git config --global --add safe.directory '*'

# Copy application source code
COPY . .
