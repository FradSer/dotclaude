// Applies a percentage discount to a cart total.
// Volume rule: orders over $100 always get at least 10% off.
export function applyDiscount(total, percent) {
  const effective = total > 100 ? percent : Math.max(percent, 10);
  return total * (1 - effective / 100);
}
