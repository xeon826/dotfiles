---
name: crawl4ai
url: https://github.com/unclecode/crawl4ai
type: remote
auth: none
description: Web crawling and data extraction for AI agents via built-in MCP support
tags: [web, crawl, scrape]
---

# Crawl4AI MCP Server

Web crawling and data extraction through MCP (Model Context Protocol). Extracts content from webpages as markdown, HTML, PDFs, or screenshots.

## Installation

Crawl4AI has built-in MCP support via Server-Sent Events (SSE) or WebSocket endpoints. No separate MCP container needed.

```jsonc
{
  "mcp": {
    "crawl4ai": {
      "type": "remote",
      "url": "http://localhost:11235/mcp/sse",
      "enabled": true
    }
  }
}
```

## Setup

1. Run Crawl4AI backend (includes MCP support):
   ```bash
   docker run -d -p 11235:11235 --name crawl4ai unclecode/crawl4ai:latest
   ```

2. No environment variables needed for MCP connection.

3. Verify MCP endpoint is accessible:
   ```bash
   curl http://localhost:11235/mcp/schema
   ```

## Tools

### `md` - Markdown Extraction
Convert webpage to clean markdown with content filtering.

**Parameters:**
- `url` (required): Target URL
- `f`: Filter strategy - `raw`, `fit` (default), `bm25`, `llm`
- `q`: Query string for BM25/LLM filtering
- `c`: Cache-bust counter (default: "0")
- `provider`: LLM provider override

**Example with filtering (recommended for large pages):**
```json
{
  "url": "https://example.com/docs",
  "f": "bm25",
  "q": "API response codes"
}
```

### `html` - Raw HTML
Get cleaned and preprocessed HTML content.

**Parameters:**
- `url` (required): Target URL

### `crawl` - Comprehensive Crawling
Crawl multiple URLs with configurable options.

**Parameters:**
- `urls` (required): Array of URLs (max 100)
- `browser_config`: Browser configuration
- `crawler_config`: Crawler configuration

### `screenshot` - Visual Capture
Take screenshots of webpages.

**Parameters:**
- `url` (required): Target URL
- `output_path`: Optional save path
- `screenshot_wait_for`: Wait time in seconds (default: 2)

### `pdf` - PDF Generation
Convert webpages to PDF documents.

**Parameters:**
- `url` (required): Target URL
- `output_path`: Optional save path

### `execute_js` - JavaScript Execution
Execute JavaScript on webpages.

**Parameters:**
- `url` (required): Target URL
- `scripts`: Array of JavaScript snippets

## Automatic Filtering Strategies

To avoid context length issues without manual query specification:

1. **URL-based Query Extraction**: Extract keywords from the URL path.
   ```json
   {
     "url": "https://example.com/docs/response-codes",
     "f": "bm25",
     "q": "response codes"
   }
   ```

2. **Page Title Extraction**: Use `html` tool to get page title, then use as query.

3. **Default BM25 with Fallback**: Start with broad query like "main content", if results too short fallback to raw.

4. **LLM Summarization**: Use `f=llm` with query "Extract the main content" (requires LLM provider).

For automated workflows, consider creating a wrapper tool that implements these heuristics.

## Troubleshooting

### Connection Errors
- Ensure Crawl4AI backend is running: `curl http://localhost:11235/health`
- Use `--network host` in Docker command for localhost access
- Check container logs: `docker logs <container-id>`

### Context Length Errors
Large webpages can exceed LLM context limits. Use filtering:
- `f=bm25` with specific `q` parameter to extract relevant content
- `f=llm` for semantic filtering (requires LLM provider)
- Start with specific queries like "response codes 200 400" instead of full page

## Links

- [Crawl4AI Main Project](https://github.com/unclecode/crawl4ai)
- [Docker Hub](https://hub.docker.com/r/unclecode/crawl4ai)
- [MCP Documentation](https://github.com/unclecode/crawl4ai?tab=readme-ov-file#mcp-model-context-protocol-support)