FROM node:24-bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends git curl ca-certificates bash jq && rm -rf /var/lib/apt/lists/*
RUN npm install -g @anthropic-ai/claude-code@2.1.295
ENV CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
WORKDIR /work
