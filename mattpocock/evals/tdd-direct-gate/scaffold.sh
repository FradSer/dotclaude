#!/usr/bin/env bash
set -euo pipefail
cat > package.json <<'EOF'
{
  "name": "fixture-app",
  "version": "1.0.0",
  "type": "module",
  "scripts": { "test": "node --test" }
}
EOF
cat > discount.js <<'EOF'
// Applies a percentage discount to a cart total.
export function applyDiscount(total, percent) {
  return total * (1 - percent / 100);
}
EOF
cat > README.md <<'EOF'
# fixture-app

Tiny cart discount helper. Run tests with `node --test`.
EOF
git init -q .
git add -A
git -c user.name=eval-scaffold -c user.email=eval@localhost -c commit.gpgsign=false commit -qm "init fixture"
