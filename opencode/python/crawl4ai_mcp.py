#!/usr/bin/env python3
"""
Crawl4AI MCP Server
Exposes web scraping tools to AI assistants via Model Context Protocol
"""

from crawl4ai import AsyncWebCrawler
from mcp.server.models import InitializationOptions
from mcp.server import NotificationOptions, Server
from mcp.server.stdio import stdio_server
from mcp.types import (
    Resource,
    Tool,
    TextContent,
    ImageContent,
    EmbeddedResource,
)
from typing import Any, Optional
import json
import asyncio
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Server("crawl4ai-server")


@app.list_tools()
async def handle_list_tools() -> list[Tool]:
    """
    List available scraping tools.
    """
    return [
        Tool(
            name="scrape_url",
            description="Scrape a single URL and return content as markdown. Handles JavaScript-heavy sites using browser automation.",
            inputSchema={
                "type": "object",
                "properties": {
                    "url": {
                        "type": "string",
                        "description": "URL to scrape (must include http:// or https://)"
                    },
                    "wait_for_selector": {
                        "type": "string",
                        "description": "Optional CSS selector to wait for before scraping (useful for dynamic content)"
                    },
                    "word_count_threshold": {
                        "type": "integer",
                        "description": "Minimum word count threshold for content extraction (default: 10)",
                        "default": 10
                    }
                },
                "required": ["url"]
            }
        ),
        Tool(
            name="extract_with_css",
            description="Extract specific elements from a page using CSS selectors. Returns matched elements.",
            inputSchema={
                "type": "object",
                "properties": {
                    "url": {
                        "type": "string",
                        "description": "URL to scrape"
                    },
                    "selector": {
                        "type": "string",
                        "description": "CSS selector for elements to extract (e.g., '.article-content', 'h2.title', 'a[href]')"
                    },
                    "attribute": {
                        "type": "string",
                        "description": "Attribute to extract from matched elements",
                        "enum": ["text", "href", "src", "innerHTML", "outerHTML"],
                        "default": "text"
                    }
                },
                "required": ["url", "selector"]
            }
        ),
        Tool(
            name="crawl_multiple",
            description="Crawl multiple pages from a website starting from a given URL. Follows internal links.",
            inputSchema={
                "type": "object",
                "properties": {
                    "url": {
                        "type": "string",
                        "description": "Starting URL for the crawl"
                    },
                    "max_pages": {
                        "type": "integer",
                        "description": "Maximum number of pages to crawl (default: 5)",
                        "default": 5
                    },
                    "delay": {
                        "type": "number",
                        "description": "Delay in seconds between requests to respect rate limits (default: 1.0)",
                        "default": 1.0
                    }
                },
                "required": ["url"]
            }
        ),
        Tool(
            name="extract_structured_data",
            description="Extract structured data from a page using a JSON schema. Useful for product info, articles, listings.",
            inputSchema={
                "type": "object",
                "properties": {
                    "url": {
                        "type": "string",
                        "description": "URL to extract data from"
                    },
                    "schema": {
                        "type": "object",
                        "description": "JSON schema describing the data structure to extract",
                        "additionalProperties": True
                    },
                    "selector": {
                        "type": "string",
                        "description": "Optional CSS selector to scope extraction to a specific area"
                    }
                },
                "required": ["url"]
            }
        ),
        Tool(
            name="get_page_links",
            description="Extract all links from a page, categorized as internal or external.",
            inputSchema={
                "type": "object",
                "properties": {
                    "url": {
                        "type": "string",
                        "description": "URL to extract links from"
                    },
                    "include_external": {
                        "type": "boolean",
                        "description": "Whether to include external links (default: true)",
                        "default": True
                    }
                },
                "required": ["url"]
            }
        )
    ]


@app.call_tool()
async def handle_call_tool(name: str, arguments: dict | None) -> list[TextContent | ImageContent | EmbeddedResource]:
    """
    Handle tool calls from MCP clients.
    """
    if arguments is None:
        arguments = {}

    try:
        if name == "scrape_url":
            return await scrape_url(
                str(arguments.get("url", "")),
                arguments.get("wait_for_selector"),
                int(arguments.get("word_count_threshold", 10))
            )
        elif name == "extract_with_css":
            return await extract_with_css(
                str(arguments.get("url", "")),
                str(arguments.get("selector", "")),
                str(arguments.get("attribute", "text"))
            )
        elif name == "crawl_multiple":
            return await crawl_multiple(
                str(arguments.get("url", "")),
                int(arguments.get("max_pages", 5)),
                float(arguments.get("delay", 1.0))
            )
        elif name == "extract_structured_data":
            return await extract_structured_data(
                str(arguments.get("url", "")),
                arguments.get("schema"),
                arguments.get("selector")
            )
        elif name == "get_page_links":
            return await get_page_links(
                str(arguments.get("url", "")),
                bool(arguments.get("include_external", True))
            )
        else:
            raise ValueError(f"Unknown tool: {name}")
    except Exception as e:
        logger.error(f"Error in {name}: {str(e)}", exc_info=True)
        return [TextContent(
            type="text",
            text=f"Error during scraping: {str(e)}\n\nTip: Check if the URL is accessible and respects robots.txt"
        )]


def validate_url(url: str) -> str | None:
    """Validate URL format and return error message if invalid."""
    if not url:
        return "URL is required"
    if not url.startswith(('http://', 'https://')):
        return "URL must start with http:// or https://"
    return None


async def scrape_url(url: str, wait_for_selector: Optional[str] = None, word_count_threshold: int = 10) -> list[TextContent]:
    """Scrape a single URL and return markdown content."""
    error = validate_url(url)
    if error:
        return [TextContent(type="text", text=f"Error: {error}")]

    logger.info(f"Scraping URL: {url}")

    async with AsyncWebCrawler(verbose=True) as crawler:
        result = await crawler.arun(
            url=url,
            word_count_threshold=word_count_threshold,
            exclude_external_links=False,
            wait_for_selector=wait_for_selector,
            page_timeout=30000  # 30 second timeout
        )

        if result.success:
            links_count = 0
            if hasattr(result, 'links'):
                links_count = len(result.links.get('internal', [])) + len(result.links.get('external', []))

            markdown_content = f"""# Scraped Content from {url}

{result.markdown}

---

## Metadata
- **Status**: Success
- **Word Count**: {getattr(result, 'extracted_content_word_count', 'N/A')}
- **Links Found**: {links_count}
- **URL**: {url}
"""
            return [TextContent(type="text", text=markdown_content)]
        else:
            error_msg = getattr(result, 'error_message', 'Unknown error')
            return [TextContent(
                type="text",
                text=f"Failed to scrape {url}\n\nError: {error_msg}"
            )]


async def extract_with_css(url: str, selector: str, attribute: str = "text") -> list[TextContent]:
    """Extract specific elements using CSS selectors."""
    error = validate_url(url)
    if error:
        return [TextContent(type="text", text=f"Error: {error}")]
    if not selector:
        return [TextContent(type="text", text="Error: CSS selector is required")]

    logger.info(f"Extracting from {url} with selector: {selector}")

    async with AsyncWebCrawler(verbose=True) as crawler:
        result = await crawler.arun(
            url=url,
            css_selector=selector,
            bypass_cache=True
        )

        if result.success:
            extracted_data = getattr(result, 'extracted_content', result.markdown)

            content = f"""# CSS Extraction Results from {url}

**Selector**: `{selector}`
**Attribute**: `{attribute}`

## Extracted Data
```
{extracted_data}
```

---

## Metadata
- **Status**: Success
- **URL**: {url}
"""
            return [TextContent(type="text", text=content)]
        else:
            error_msg = getattr(result, 'error_message', 'Unknown error')
            return [TextContent(
                type="text",
                text=f"CSS extraction failed for {url}\n\nError: {error_msg}"
            )]


async def crawl_multiple(url: str, max_pages: int = 5, delay: float = 1.0) -> list[TextContent]:
    """Crawl multiple pages from a starting URL."""
    error = validate_url(url)
    if error:
        return [TextContent(type="text", text=f"Error: {error}")]

    logger.info(f"Starting multi-page crawl from {url}, max_pages={max_pages}")

    results = []
    async with AsyncWebCrawler(verbose=True) as crawler:
        # Crawl first page
        result = await crawler.arun(url=url, word_count_threshold=10)

        if result.success:
            results.append(f"## Page 1: {url}\n\n{result.markdown[:2000]}...\n")

            # Get internal links for further crawling
            if hasattr(result, 'links'):
                internal_links = result.links.get('internal', [])[:max_pages-1]

                for i, link in enumerate(internal_links, 2):
                    if i > max_pages:
                        break
                    try:
                        await asyncio.sleep(delay)  # Rate limiting
                        page_result = await crawler.arun(url=link, word_count_threshold=10)
                        if page_result.success:
                            results.append(f"## Page {i}: {link}\n\n{page_result.markdown[:2000]}...\n")
                            logger.info(f"Crawled page {i}: {link}")
                    except Exception as e:
                        results.append(f"## Page {i}: {link}\n\nError: {str(e)}\n")
                        logger.error(f"Failed to crawl {link}: {str(e)}")

        content = f"""# Multi-Page Crawl Results from {url}

**Pages Crawled**: {len(results)}
**Max Pages**: {max_pages}
**Delay Between Requests**: {delay}s

---

{chr(10).join(results)}

---

## Summary
- **Total Pages**: {len(results)}
- **Starting URL**: {url}
"""
        return [TextContent(type="text", text=content)]


async def extract_structured_data(url: str, schema: Optional[dict] = None, selector: Optional[str] = None) -> list[TextContent]:
    """Extract structured data from a page using CSS-based extraction."""
    error = validate_url(url)
    if error:
        return [TextContent(type="text", text=f"Error: {error}")]

    logger.info(f"Extracting structured data from {url}")

    async with AsyncWebCrawler(verbose=True) as crawler:
        kwargs = {
            "url": url,
            "word_count_threshold": 5,
            "bypass_cache": True
        }
        if selector:
            kwargs["css_selector"] = selector

        result = await crawler.arun(**kwargs)

        if result.success:
            content = f"""# Structured Data Extraction from {url}

**Selector**: `{selector or 'full page'}`
**Schema**: {json.dumps(schema, indent=2) if schema else 'Not specified'}

## Extracted Content
```
{result.markdown}
```

---

## Metadata
- **Status**: Success
- **URL**: {url}
"""
            return [TextContent(type="text", text=content)]
        else:
            error_msg = getattr(result, 'error_message', 'Unknown error')
            return [TextContent(
                type="text",
                text=f"Structured extraction failed for {url}\n\nError: {error_msg}"
            )]


async def get_page_links(url: str, include_external: bool = True) -> list[TextContent]:
    """Extract all links from a page."""
    error = validate_url(url)
    if error:
        return [TextContent(type="text", text=f"Error: {error}")]

    logger.info(f"Extracting links from {url}")

    async with AsyncWebCrawler(verbose=True) as crawler:
        result = await crawler.arun(url=url, word_count_threshold=5)

        if result.success:
            internal_links = []
            external_links = []

            if hasattr(result, 'links'):
                internal_links = result.links.get('internal', [])
                external_links = result.links.get('external', [])

            content = f"""# Links from {url}

## Internal Links ({len(internal_links)})
"""
            for link in internal_links[:50]:  # Limit output
                content += f"- {link}\n"

            if include_external and external_links:
                content += f"\n## External Links ({len(external_links)})\n"
                for link in external_links[:50]:  # Limit output
                    content += f"- {link}\n"

            content += f"""
---

## Summary
- **Internal Links**: {len(internal_links)}
- **External Links**: {len(external_links)}
- **Total Links**: {len(internal_links) + len(external_links)}
- **URL**: {url}
"""
            return [TextContent(type="text", text=content)]
        else:
            error_msg = getattr(result, 'error_message', 'Unknown error')
            return [TextContent(
                type="text",
                text=f"Link extraction failed for {url}\n\nError: {error_msg}"
            )]


async def main():
    """Run the MCP server."""
    logger.info("Starting Crawl4AI MCP Server")
    async with stdio_server() as (read_stream, write_stream):
        await app.run(
            read_stream,
            write_stream,
            InitializationOptions(
                server_name="crawl4ai-server",
                server_version="1.0.0",
                capabilities=app.get_capabilities(
                    notification_options=NotificationOptions(),
                    experimental_capabilities={}
                )
            )
        )


if __name__ == "__main__":
    asyncio.run(main())
