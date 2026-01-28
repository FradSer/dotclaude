---
title: Threading
impact: CRITICAL
impactDescription: Prevents race conditions and unpredictable behavior
tags: threading, concurrency, locks
---

## Threading

**Impact: CRITICAL (Prevents race conditions and unpredictable behavior)**

Python's built-in types (dict, list) are **not** guaranteed to be atomic.

### Guidelines
- **Communication**: Prefer `queue.Queue` over shared memory. It handles locking automatically.
- **Locks**:
    - Use `threading.Lock` for low-level exclusion.
    - Always use locks with the `with lock:` statement (Context Manager) to ensure release on exception.
    - Do not assume `a += 1` is atomic.
- **Spawning**:
    - Use `threading.Thread` or `concurrent.futures`.
    - Avoid low-level `_thread` module.
    - Daemon threads: Be careful; they abruptly stop on exit, potentially leaving resources corrupted.
- **Condition Variables**: Use `threading.Condition` instead of busy-waiting loops (`while not done: sleep()`).

**Incorrect (Busy Wait):**
```python
while not shared_data_ready:
    time.sleep(0.1)  # Wasteful and imprecise
```

**Correct (Condition):**
```python
with condition:
    while not shared_data_ready:
        condition.wait()
```

**Incorrect (Implicit Atomicity):**
```python
counter = 0
def worker():
    global counter
    counter += 1  # Not atomic!
```

**Correct (Locking):**
```python
counter = 0
lock = threading.Lock()
def worker():
    with lock:
        counter += 1
```

Reference: [Google Python Style Guide - Threading](https://google.github.io/styleguide/pyguide.html#218-threading)