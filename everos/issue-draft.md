# Issue draft for EverMind-AI/EverOS — extraction JSONDecodeError + /flush 500
<!-- FILED as https://github.com/EverMind-AI/EverOS/issues/564 (2026-11-05, account xeon826) -->

**Title:** `memorize_extraction_failed` with strict `json.loads` on lax LLM JSON; extraction error crashes `/flush` with 500

## Environment

- everos 1.5.1 (uv tool install), everalgo vendored
- `[llm]` provider: DeepSeek (`deepseek-chat`, OpenAI-compatible), embeddings: DashScope `text-embedding-v4`
- Observed under real multi-session traffic (~170 `/add`, ~50 `/flush` per day)

## Symptoms

Intermittent (14 occurrences in ~30h) on flush-triggered extraction:

```
memorize_extraction_failed  error='JSONDecodeError: Expecting property name enclosed in double quotes: line 4 column 1 (char 2954)'
unhandled_exception         exception_type=JSONDecodeError path=/api/v2/memory/flush
```

- The parse failure is **unhandled at the route level**: `POST /api/v2/memory/flush` returns 500 instead of degrading gracefully; the memcells stay buffered and retry later, delaying memory availability and logging a traceback every time.
- `episode_extract_retry` re-prompts, but retries reproduce the same malformed JSON.

## Root cause

LLM output (DeepSeek in our case) is occasionally **not strict RFC-8259 JSON** — e.g. trailing commas before a closing brace (`{..., }`), which produces exactly `Expecting property name enclosed in double quotes: line N column 1`. The extraction path does strict parsing with no repair:

- `everalgo/user_memory/episode.py`: `_extract_json_object()` (brace-balanced substring) → bare `json.loads(json_str)` — no `response_format={"type":"json_object"}` enforcement, no sanitization.
- Same pattern in `profile.py` (×3 sites), `atomic_fact.py`, `foresight.py`. (`everalgo.llm.parse.parse_llm_json_object` already has a multi-strategy parser, but these modules don't use it.)

GLM and some other providers happen to emit strict JSON, which masks the bug; switching providers exposes it.

## Suggested fixes (any one suffices; first is smallest)

1. One repair pass before strict parsing: strip commas directly preceding `}` / `]`, e.g. `re.sub(r",\s*([}\]])", r"\1", json_str)` on `JSONDecodeError`, retry once.
2. Route all extractor call sites through `everalgo.llm.parse.parse_llm_json_object` and add the same repair as a strategy there (single choke point — the four `_extract_json_object` copies are already duplicated).
3. Optionally enforce `response_format={"type": "json_object"}` for OpenAI-compatible providers that support it.
4. Separately: catch extraction exceptions in the `/flush` handler and return a structured error envelope instead of an unhandled 500.

## Repro

Any OpenAI-compatible model that emits a trailing comma (DeepSeek `deepseek-chat` does this intermittently) + a flush that triggers episode extraction. Local repro of the parse failure: `json.loads('{\n"title": "<1200 chars>",\n"content": "<1500 chars>",\n}')` → `JSONDecodeError: Expecting property name enclosed in double quotes: line 4 column 1`.

## Local workaround

Patched the four modules with a `_loads_lenient` helper (repair-once-on-JSONDecodeError); failures stopped. Happy to send the diff/PR.
