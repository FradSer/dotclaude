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
