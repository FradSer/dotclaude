#!/usr/bin/env bash
set -euo pipefail
cat > package.json <<'EOF'
{
  "name": "buggy-app",
  "version": "1.0.0",
  "type": "module",
  "scripts": { "test": "node --test" }
}
EOF
cat > discount.js <<'EOF'
// Applies a percentage discount to a cart total.
// Volume rule: orders over $100 always get at least 10% off.
export function applyDiscount(total, percent) {
  const effective = total > 100 ? percent : Math.max(percent, 10);
  return total * (1 - effective / 100);
}
EOF
cat > discount.test.js <<'EOF'
import { test } from "node:test";
import assert from "node:assert";
import { applyDiscount } from "./discount.js";

test("small order without volume rule keeps its own percent", () => {
  assert.strictEqual(applyDiscount(50, 5), 47.5);
});

test("large order gets at least 10% off", () => {
  assert.strictEqual(applyDiscount(200, 0), 180);
});

test("large order with bigger percent uses the bigger percent", () => {
  assert.strictEqual(applyDiscount(200, 15), 170);
});
EOF
cat > README.md <<'EOF'
# buggy-app

Cart discount helper with a reported bug. Tests: `node --test`.

Reported symptom: `applyDiscount(50, 5)` returns 45, but a $50 order with a
5% promo should cost 47.50 — small orders are being discounted 10% instead of
the requested percent. Larger orders sometimes also get the wrong rate.
EOF
git init -q .
git add -A
git -c user.name=eval-scaffold -c user.email=eval@localhost -c commit.gpgsign=false commit -qm "init fixture"
