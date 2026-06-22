# React/Next.js Performance Patterns Index

Complete index of all 57 React/Next.js performance optimization patterns, organized by category and impact level.

**Quick Navigation:**
- [By Impact Level](#by-impact-level)
- [By Category](#by-category)
- [Pattern Summary](#pattern-summary)

---

## By Impact Level

### CRITICAL Impact (7 patterns)
These patterns have direct, measurable impact on user experience. Fix these first.

**Eliminating Waterfalls (async):**
- [async-api-routes.md](async-api-routes.md) - Optimize API route handlers
- [async-dependencies.md](async-dependencies.md) - Handle async dependencies efficiently
- [async-parallel.md](async-parallel.md) - Parallelize independent operations

**Bundle Size Optimization (bundle):**
- [bundle-barrel-imports.md](bundle-barrel-imports.md) - Avoid barrel file performance issues
- [bundle-dynamic-imports.md](bundle-dynamic-imports.md) - Code splitting with dynamic imports

**Server-Side Performance (server):**
- [server-auth-actions.md](server-auth-actions.md) - Authenticate server actions like API routes
- [server-parallel-fetching.md](server-parallel-fetching.md) - Parallelize server data fetching

### HIGH Impact (6 patterns)
Significant performance or maintainability improvements.

**Eliminating Waterfalls (async):**
- [async-defer-await.md](async-defer-await.md) - Defer non-critical async operations
- [async-suspense-boundaries.md](async-suspense-boundaries.md) - Strategic Suspense boundary placement

**Bundle Size Optimization (bundle):**
- [bundle-conditional.md](bundle-conditional.md) - Conditional imports based on runtime

**Rendering Performance (rendering):**
- [rendering-content-visibility.md](rendering-content-visibility.md) - CSS content-visibility

**Server-Side Performance (server):**
- [server-cache-lru.md](server-cache-lru.md) - LRU caching strategies
- [server-serialization.md](server-serialization.md) - Efficient data serialization

### MEDIUM-HIGH Impact (3 patterns)
Noticeable improvements in client-side performance.

**Client-Side Data Fetching (client):**
- [client-swr-dedup.md](client-swr-dedup.md) - Automatic request deduplication

**JavaScript Performance (js):**
- [js-length-check-first.md](js-length-check-first.md) - Check length before iteration
- [js-tosorted-immutable.md](js-tosorted-immutable.md) - Use toSorted for immutability

### MEDIUM Impact (20 patterns)
Reduces unnecessary computation and improves UI responsiveness.

**Bundle Size Optimization (bundle):**
- [bundle-defer-third-party.md](bundle-defer-third-party.md) - Defer third-party scripts
- [bundle-preload.md](bundle-preload.md) - Preload critical resources

**Client-Side Data Fetching (client):**
- [client-localstorage-schema.md](client-localstorage-schema.md) - LocalStorage schema validation
- [client-passive-event-listeners.md](client-passive-event-listeners.md) - Passive event listeners

**JavaScript Performance (js):**
- [js-batch-dom-css.md](js-batch-dom-css.md) - Batch DOM/CSS updates
- [js-cache-function-results.md](js-cache-function-results.md) - Memoize function results

**Re-render Optimization (rerender):**
- [rerender-defer-reads.md](rerender-defer-reads.md) - Defer expensive reads
- [rerender-derived-state.md](rerender-derived-state.md) - Avoid derived state anti-patterns
- [rerender-derived-state-no-effect.md](rerender-derived-state-no-effect.md) - Calculate derived state during rendering
- [rerender-functional-setstate.md](rerender-functional-setstate.md) - Functional state updates
- [rerender-lazy-state-init.md](rerender-lazy-state-init.md) - Lazy state initialization
- [rerender-memo.md](rerender-memo.md) - Memoization with React.memo and useMemo
- [rerender-memo-with-default-value.md](rerender-memo-with-default-value.md) - Hoist default non-primitive props
- [rerender-move-effect-to-event.md](rerender-move-effect-to-event.md) - Put interaction logic in event handlers
- [rerender-transitions.md](rerender-transitions.md) - Use transitions for non-urgent updates
- [rerender-use-ref-transient-values.md](rerender-use-ref-transient-values.md) - Use refs for transient frequent values

**Rendering Performance (rendering):**
- [rendering-activity.md](rendering-activity.md) - Optimize activity indicators
- [rendering-hydration-no-flicker.md](rendering-hydration-no-flicker.md) - Prevent hydration flicker

**Server-Side Performance (server):**
- [server-after-nonblocking.md](server-after-nonblocking.md) - Non-blocking after() API
- [server-cache-react.md](server-cache-react.md) - React cache for deduplication

### LOW-MEDIUM Impact (10 patterns)
Micro-optimizations for hot paths.

**Advanced Patterns (advanced):**
- [advanced-init-once.md](advanced-init-once.md) - Initialize app once per app load

**JavaScript Performance (js):**
- [js-cache-property-access.md](js-cache-property-access.md) - Cache property access
- [js-cache-storage.md](js-cache-storage.md) - Cache expensive storage access
- [js-combine-iterations.md](js-combine-iterations.md) - Combine multiple iterations
- [js-early-exit.md](js-early-exit.md) - Early exit patterns
- [js-hoist-regexp.md](js-hoist-regexp.md) - Hoist RegExp outside functions
- [js-index-maps.md](js-index-maps.md) - Index maps for fast lookups
- [js-set-map-lookups.md](js-set-map-lookups.md) - Use Set/Map for O(1) lookups

**Rendering Performance (rendering):**
- [rendering-hydration-suppress-warning.md](rendering-hydration-suppress-warning.md) - Suppress expected hydration mismatches

**Re-render Optimization (rerender):**
- [rerender-simple-expression-in-memo.md](rerender-simple-expression-in-memo.md) - Avoid memo for simple primitives

### LOW Impact (11 patterns)
Advanced patterns for specific edge cases.

**Advanced Patterns (advanced):**
- [advanced-event-handler-refs.md](advanced-event-handler-refs.md) - Event handler refs pattern
- [advanced-use-latest.md](advanced-use-latest.md) - useLatest hook for stable refs

**Client-Side Data Fetching (client):**
- [client-event-listeners.md](client-event-listeners.md) - Efficient event listener management

**JavaScript Performance (js):**
- [js-min-max-loop.md](js-min-max-loop.md) - Min/max without extra loops

**Rendering Performance (rendering):**
- [rendering-animate-svg-wrapper.md](rendering-animate-svg-wrapper.md) - Efficient SVG animations
- [rendering-conditional-render.md](rendering-conditional-render.md) - Optimize conditional rendering
- [rendering-hoist-jsx.md](rendering-hoist-jsx.md) - Hoist JSX outside render
- [rendering-svg-precision.md](rendering-svg-precision.md) - SVG precision optimization
- [rendering-usetransition-loading.md](rendering-usetransition-loading.md) - Prefer useTransition for loading state

**Re-render Optimization (rerender):**
- [rerender-dependencies.md](rerender-dependencies.md) - Correct dependency arrays

**Server-Side Performance (server):**
- [server-dedup-props.md](server-dedup-props.md) - Avoid duplicate serialization in RSC props

---

## By Category

### 1. Eliminating Waterfalls (async) - CRITICAL/HIGH
**5 patterns** | Waterfalls are the #1 performance killer

- [async-api-routes.md](async-api-routes.md)
- [async-defer-await.md](async-defer-await.md)
- [async-dependencies.md](async-dependencies.md)
- [async-parallel.md](async-parallel.md)
- [async-suspense-boundaries.md](async-suspense-boundaries.md)

### 2. Bundle Size Optimization (bundle) - CRITICAL/MEDIUM
**5 patterns** | Reduce initial bundle size for faster TTI

- [bundle-barrel-imports.md](bundle-barrel-imports.md)
- [bundle-conditional.md](bundle-conditional.md)
- [bundle-defer-third-party.md](bundle-defer-third-party.md)
- [bundle-dynamic-imports.md](bundle-dynamic-imports.md)
- [bundle-preload.md](bundle-preload.md)

### 3. Server-Side Performance (server) - CRITICAL/HIGH/MEDIUM/LOW
**7 patterns** | Optimize server rendering and data fetching

- [server-after-nonblocking.md](server-after-nonblocking.md)
- [server-auth-actions.md](server-auth-actions.md)
- [server-cache-lru.md](server-cache-lru.md)
- [server-cache-react.md](server-cache-react.md)
- [server-dedup-props.md](server-dedup-props.md)
- [server-parallel-fetching.md](server-parallel-fetching.md)
- [server-serialization.md](server-serialization.md)

### 4. Client-Side Data Fetching (client) - MEDIUM-HIGH/MEDIUM/LOW
**4 patterns** | Efficient data fetching on the client

- [client-event-listeners.md](client-event-listeners.md)
- [client-localstorage-schema.md](client-localstorage-schema.md)
- [client-passive-event-listeners.md](client-passive-event-listeners.md)
- [client-swr-dedup.md](client-swr-dedup.md)

### 5. Re-render Optimization (rerender) - MEDIUM/LOW-MEDIUM/LOW
**12 patterns** | Reduce unnecessary re-renders

- [rerender-defer-reads.md](rerender-defer-reads.md)
- [rerender-dependencies.md](rerender-dependencies.md)
- [rerender-derived-state.md](rerender-derived-state.md)
- [rerender-derived-state-no-effect.md](rerender-derived-state-no-effect.md)
- [rerender-functional-setstate.md](rerender-functional-setstate.md)
- [rerender-lazy-state-init.md](rerender-lazy-state-init.md)
- [rerender-memo.md](rerender-memo.md)
- [rerender-memo-with-default-value.md](rerender-memo-with-default-value.md)
- [rerender-move-effect-to-event.md](rerender-move-effect-to-event.md)
- [rerender-simple-expression-in-memo.md](rerender-simple-expression-in-memo.md)
- [rerender-transitions.md](rerender-transitions.md)
- [rerender-use-ref-transient-values.md](rerender-use-ref-transient-values.md)

### 6. Rendering Performance (rendering) - HIGH/MEDIUM/LOW-MEDIUM/LOW
**9 patterns** | Optimize the rendering process

- [rendering-activity.md](rendering-activity.md)
- [rendering-animate-svg-wrapper.md](rendering-animate-svg-wrapper.md)
- [rendering-conditional-render.md](rendering-conditional-render.md)
- [rendering-content-visibility.md](rendering-content-visibility.md)
- [rendering-hoist-jsx.md](rendering-hoist-jsx.md)
- [rendering-hydration-no-flicker.md](rendering-hydration-no-flicker.md)
- [rendering-hydration-suppress-warning.md](rendering-hydration-suppress-warning.md)
- [rendering-svg-precision.md](rendering-svg-precision.md)
- [rendering-usetransition-loading.md](rendering-usetransition-loading.md)

### 7. JavaScript Performance (js) - MEDIUM-HIGH/MEDIUM/LOW-MEDIUM/LOW
**12 patterns** | Micro-optimizations for hot paths

- [js-batch-dom-css.md](js-batch-dom-css.md)
- [js-cache-function-results.md](js-cache-function-results.md)
- [js-cache-property-access.md](js-cache-property-access.md)
- [js-cache-storage.md](js-cache-storage.md)
- [js-combine-iterations.md](js-combine-iterations.md)
- [js-early-exit.md](js-early-exit.md)
- [js-hoist-regexp.md](js-hoist-regexp.md)
- [js-index-maps.md](js-index-maps.md)
- [js-length-check-first.md](js-length-check-first.md)
- [js-min-max-loop.md](js-min-max-loop.md)
- [js-set-map-lookups.md](js-set-map-lookups.md)
- [js-tosorted-immutable.md](js-tosorted-immutable.md)

### 8. Advanced Patterns (advanced) - LOW-MEDIUM/LOW
**3 patterns** | Advanced patterns for specific cases

- [advanced-event-handler-refs.md](advanced-event-handler-refs.md)
- [advanced-init-once.md](advanced-init-once.md)
- [advanced-use-latest.md](advanced-use-latest.md)

---

## Pattern Summary

**Total Patterns:** 57

**By Impact:**
- CRITICAL: 7 patterns (12%)
- HIGH: 6 patterns (11%)
- MEDIUM-HIGH: 3 patterns (5%)
- MEDIUM: 20 patterns (35%)
- LOW-MEDIUM: 10 patterns (18%)
- LOW: 11 patterns (19%)

**By Category:**
- Async: 5 patterns
- Bundle: 5 patterns
- Server: 7 patterns
- Client: 4 patterns
- Re-render: 12 patterns
- Rendering: 9 patterns
- JavaScript: 12 patterns
- Advanced: 3 patterns

---

## How to Use This Index

1. **Start with CRITICAL patterns**: These have the largest impact on user experience
2. **Focus on your bottlenecks**: Use profiling to identify which categories matter most
3. **Read pattern files**: Each pattern includes before/after examples and detailed explanations
4. **Use impact-based prioritization**: The refactor plugin automatically prioritizes CRITICAL > HIGH > MEDIUM > LOW

## Related Files

- [_sections.md](_sections.md) - Category descriptions and impact levels
- [_template.md](_template.md) - Template for creating new patterns
