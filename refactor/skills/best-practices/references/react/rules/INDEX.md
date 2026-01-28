# Next.js Performance Patterns Index

Complete index of all 47 Next.js performance optimization patterns, organized by category and impact level.

**Quick Navigation:**
- [By Impact Level](#by-impact-level)
- [By Category](#by-category)
- [Pattern Summary](#pattern-summary)

---

## By Impact Level

### CRITICAL Impact (12 patterns)
These patterns have direct, measurable impact on user experience. Fix these first.

**Eliminating Waterfalls (async):**
- [async-defer-await.md](async-defer-await.md) - Defer non-critical async operations
- [async-parallel.md](async-parallel.md) - Parallelize independent operations
- [async-api-routes.md](async-api-routes.md) - Optimize API route handlers
- [async-dependencies.md](async-dependencies.md) - Handle async dependencies efficiently
- [async-suspense-boundaries.md](async-suspense-boundaries.md) - Strategic Suspense boundary placement

**Bundle Size Optimization (bundle):**
- [bundle-dynamic-imports.md](bundle-dynamic-imports.md) - Code splitting with dynamic imports
- [bundle-conditional.md](bundle-conditional.md) - Conditional imports based on runtime
- [bundle-barrel-imports.md](bundle-barrel-imports.md) - Avoid barrel file performance issues
- [bundle-defer-third-party.md](bundle-defer-third-party.md) - Defer third-party scripts
- [bundle-preload.md](bundle-preload.md) - Preload critical resources

### HIGH Impact (7 patterns)
Significant performance or maintainability improvements.

**Server-Side Performance (server):**
- [server-parallel-fetching.md](server-parallel-fetching.md) - Parallelize server data fetching
- [server-cache-react.md](server-cache-react.md) - React cache for deduplication
- [server-cache-lru.md](server-cache-lru.md) - LRU caching strategies
- [server-after-nonblocking.md](server-after-nonblocking.md) - Non-blocking after() API
- [server-serialization.md](server-serialization.md) - Efficient data serialization

### MEDIUM-HIGH Impact (4 patterns)
Noticeable improvements in client-side performance.

**Client-Side Data Fetching (client):**
- [client-swr-dedup.md](client-swr-dedup.md) - Automatic request deduplication
- [client-event-listeners.md](client-event-listeners.md) - Efficient event listener management
- [client-passive-event-listeners.md](client-passive-event-listeners.md) - Passive event listeners
- [client-localstorage-schema.md](client-localstorage-schema.md) - LocalStorage schema validation

### MEDIUM Impact (14 patterns)
Reduces unnecessary computation and improves UI responsiveness.

**Re-render Optimization (rerender):**
- [rerender-memo.md](rerender-memo.md) - Memoization with React.memo and useMemo
- [rerender-dependencies.md](rerender-dependencies.md) - Correct dependency arrays
- [rerender-derived-state.md](rerender-derived-state.md) - Avoid derived state anti-patterns
- [rerender-functional-setstate.md](rerender-functional-setstate.md) - Functional state updates
- [rerender-lazy-state-init.md](rerender-lazy-state-init.md) - Lazy state initialization
- [rerender-defer-reads.md](rerender-defer-reads.md) - Defer expensive reads
- [rerender-transitions.md](rerender-transitions.md) - Use transitions for non-urgent updates

**Rendering Performance (rendering):**
- [rendering-hoist-jsx.md](rendering-hoist-jsx.md) - Hoist JSX outside render
- [rendering-conditional-render.md](rendering-conditional-render.md) - Optimize conditional rendering
- [rendering-content-visibility.md](rendering-content-visibility.md) - CSS content-visibility
- [rendering-hydration-no-flicker.md](rendering-hydration-no-flicker.md) - Prevent hydration flicker
- [rendering-activity.md](rendering-activity.md) - Optimize activity indicators
- [rendering-animate-svg-wrapper.md](rendering-animate-svg-wrapper.md) - Efficient SVG animations
- [rendering-svg-precision.md](rendering-svg-precision.md) - SVG precision optimization

### LOW-MEDIUM Impact (12 patterns)
Micro-optimizations for hot paths.

**JavaScript Performance (js):**
- [js-early-exit.md](js-early-exit.md) - Early exit patterns
- [js-set-map-lookups.md](js-set-map-lookups.md) - Use Set/Map for O(1) lookups
- [js-cache-property-access.md](js-cache-property-access.md) - Cache property access
- [js-cache-function-results.md](js-cache-function-results.md) - Memoize function results
- [js-combine-iterations.md](js-combine-iterations.md) - Combine multiple iterations
- [js-length-check-first.md](js-length-check-first.md) - Check length before iteration
- [js-batch-dom-css.md](js-batch-dom-css.md) - Batch DOM/CSS updates
- [js-hoist-regexp.md](js-hoist-regexp.md) - Hoist RegExp outside functions
- [js-tosorted-immutable.md](js-tosorted-immutable.md) - Use toSorted for immutability
- [js-index-maps.md](js-index-maps.md) - Index maps for fast lookups
- [js-min-max-loop.md](js-min-max-loop.md) - Min/max without extra loops
- [js-cache-storage.md](js-cache-storage.md) - Cache expensive storage access

### LOW Impact (2 patterns)
Advanced patterns for specific edge cases.

**Advanced Patterns (advanced):**
- [advanced-use-latest.md](advanced-use-latest.md) - useLatest hook for stable refs
- [advanced-event-handler-refs.md](advanced-event-handler-refs.md) - Event handler refs pattern

---

## By Category

### 1. Eliminating Waterfalls (async) - CRITICAL
**5 patterns** | Waterfalls are the #1 performance killer

- [async-defer-await.md](async-defer-await.md)
- [async-parallel.md](async-parallel.md)
- [async-api-routes.md](async-api-routes.md)
- [async-dependencies.md](async-dependencies.md)
- [async-suspense-boundaries.md](async-suspense-boundaries.md)

### 2. Bundle Size Optimization (bundle) - CRITICAL
**5 patterns** | Reduce initial bundle size for faster TTI

- [bundle-dynamic-imports.md](bundle-dynamic-imports.md)
- [bundle-conditional.md](bundle-conditional.md)
- [bundle-barrel-imports.md](bundle-barrel-imports.md)
- [bundle-defer-third-party.md](bundle-defer-third-party.md)
- [bundle-preload.md](bundle-preload.md)

### 3. Server-Side Performance (server) - HIGH
**5 patterns** | Optimize server rendering and data fetching

- [server-parallel-fetching.md](server-parallel-fetching.md)
- [server-cache-react.md](server-cache-react.md)
- [server-cache-lru.md](server-cache-lru.md)
- [server-after-nonblocking.md](server-after-nonblocking.md)
- [server-serialization.md](server-serialization.md)

### 4. Client-Side Data Fetching (client) - MEDIUM-HIGH
**4 patterns** | Efficient data fetching on the client

- [client-swr-dedup.md](client-swr-dedup.md)
- [client-event-listeners.md](client-event-listeners.md)
- [client-passive-event-listeners.md](client-passive-event-listeners.md)
- [client-localstorage-schema.md](client-localstorage-schema.md)

### 5. Re-render Optimization (rerender) - MEDIUM
**7 patterns** | Reduce unnecessary re-renders

- [rerender-memo.md](rerender-memo.md)
- [rerender-dependencies.md](rerender-dependencies.md)
- [rerender-derived-state.md](rerender-derived-state.md)
- [rerender-functional-setstate.md](rerender-functional-setstate.md)
- [rerender-lazy-state-init.md](rerender-lazy-state-init.md)
- [rerender-defer-reads.md](rerender-defer-reads.md)
- [rerender-transitions.md](rerender-transitions.md)

### 6. Rendering Performance (rendering) - MEDIUM
**7 patterns** | Optimize the rendering process

- [rendering-hoist-jsx.md](rendering-hoist-jsx.md)
- [rendering-conditional-render.md](rendering-conditional-render.md)
- [rendering-content-visibility.md](rendering-content-visibility.md)
- [rendering-hydration-no-flicker.md](rendering-hydration-no-flicker.md)
- [rendering-activity.md](rendering-activity.md)
- [rendering-animate-svg-wrapper.md](rendering-animate-svg-wrapper.md)
- [rendering-svg-precision.md](rendering-svg-precision.md)

### 7. JavaScript Performance (js) - LOW-MEDIUM
**12 patterns** | Micro-optimizations for hot paths

- [js-early-exit.md](js-early-exit.md)
- [js-set-map-lookups.md](js-set-map-lookups.md)
- [js-cache-property-access.md](js-cache-property-access.md)
- [js-cache-function-results.md](js-cache-function-results.md)
- [js-combine-iterations.md](js-combine-iterations.md)
- [js-length-check-first.md](js-length-check-first.md)
- [js-batch-dom-css.md](js-batch-dom-css.md)
- [js-hoist-regexp.md](js-hoist-regexp.md)
- [js-tosorted-immutable.md](js-tosorted-immutable.md)
- [js-index-maps.md](js-index-maps.md)
- [js-min-max-loop.md](js-min-max-loop.md)
- [js-cache-storage.md](js-cache-storage.md)

### 8. Advanced Patterns (advanced) - LOW
**2 patterns** | Advanced patterns for specific cases

- [advanced-use-latest.md](advanced-use-latest.md)
- [advanced-event-handler-refs.md](advanced-event-handler-refs.md)

---

## Pattern Summary

**Total Patterns:** 47

**By Impact:**
- CRITICAL: 10 patterns (21%)
- HIGH: 5 patterns (11%)
- MEDIUM-HIGH: 4 patterns (9%)
- MEDIUM: 14 patterns (30%)
- LOW-MEDIUM: 12 patterns (26%)
- LOW: 2 patterns (4%)

**By Category:**
- Async: 5 patterns
- Bundle: 5 patterns
- Server: 5 patterns
- Client: 4 patterns
- Re-render: 7 patterns
- Rendering: 7 patterns
- JavaScript: 12 patterns
- Advanced: 2 patterns

---

## How to Use This Index

1. **Start with CRITICAL patterns**: These have the largest impact on user experience
2. **Focus on your bottlenecks**: Use profiling to identify which categories matter most
3. **Read pattern files**: Each pattern includes before/after examples and detailed explanations
4. **Use impact-based prioritization**: The refactor plugin automatically prioritizes CRITICAL > HIGH > MEDIUM > LOW

## Related Files

- [_sections.md](_sections.md) - Category descriptions and impact levels
- [_template.md](_template.md) - Template for creating new patterns