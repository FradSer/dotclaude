## Next.js Best Practices References

This directory contains Next.js performance best-practice rule files designed for agent consumption.

### How to use

1. Start with `_sections.md` to understand categories and impact levels.
2. Read the specific rule file(s) that match the pattern observed in the target code.
3. Apply the rule only when it improves the target without changing behavior.

### Naming conventions

- `async-*`: eliminate waterfalls and improve concurrency
- `bundle-*`: reduce bundle size and improve TTI/LCP
- `server-*`: server-side performance and RSC boundary optimization
- `client-*`: client data fetching and event patterns
- `rerender-*`: reduce unnecessary re-renders
- `rendering-*`: rendering pipeline and hydration correctness
- `js-*`: JavaScript micro-optimizations for hot paths
- `advanced-*`: advanced patterns for specific cases
