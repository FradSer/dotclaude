#!/usr/bin/env bash
set -euo pipefail
cat > package.json <<'EOF'
{
  "name": "workers-app",
  "version": "1.0.0",
  "type": "module"
}
EOF
cat > wrangler.toml <<'EOF'
name = "workers-app"
main = "src/index.js"
compatibility_date = "2026-01-01"

[[d1_databases]]
binding = "DB"
database_name = "app-db"
database_id = "REPLACE_ME"
EOF
mkdir -p .github/workflows
cat > .github/workflows/deploy.yml <<'EOF'
name: deploy
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: production
    steps:
      - uses: actions/checkout@v4
      - run: npx wrangler deploy
        env:
          CLOUDFLARE_API_TOKEN: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          STRIPE_WEBHOOK_SECRET: ${{ secrets.STRIPE_WEBHOOK_SECRET }}
EOF
git init -q .
git add -A
git -c user.name=eval-scaffold -c user.email=eval@localhost -c commit.gpgsign=false commit -qm "init fixture"
