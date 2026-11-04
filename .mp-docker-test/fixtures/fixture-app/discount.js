// Applies a percentage discount to a cart total.
export function applyDiscount(total, percent) {
  return total * (1 - percent / 100);
}
