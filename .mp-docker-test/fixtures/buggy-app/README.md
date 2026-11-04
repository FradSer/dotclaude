# buggy-app

Cart discount helper with a reported bug. Tests: `npm test`.

Reported symptom: `applyDiscount(50, 5)` returns 45, but a $50 order with a
5% promo should cost 47.50 — small orders are being discounted 10% instead of
the requested percent. Larger orders sometimes also get the wrong rate.
