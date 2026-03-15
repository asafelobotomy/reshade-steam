---
name: mcp-builder
description: Create a new MCP server — clarify purpose, choose transport, scaffold, implement, test, and register
compatibility: ">=2.0"
---

# MCP Server Builder

> Skill metadata: version "1.1"; license MIT; tags [mcp, server, tool, integration, scaffold]; compatibility ">=2.0"; recommended tools [codebase, editFiles, runCommands].

Build a new Model Context Protocol (MCP) server from scratch.

## When to activate

- User says "Build an MCP server", "Create an MCP server for ...", or "I need an MCP integration for ..."
- A task requires external data or capabilities not covered by existing MCP servers
- The §13 MCP decision tree reaches step 4 (BUILD)

## Workflow

### 1. Clarify purpose
Ask for capability, tools, resources, and credential needs.

### 2. Choose transport
Default to stdio unless remote use is needed.

### 3. Scaffold the server
Based on project stack (TypeScript/JavaScript or Python).

### 4. Implement tools
Define schemas, implement handlers, register with server.

### 5. Test with MCP Inspector
```bash
npx @modelcontextprotocol/inspector tsx .mcp-servers/<server-name>/src/index.ts
```

### 6. Register in `.vscode/mcp.json`

### 7. Document

## Verify

- [ ] Server starts via stdio and responds to `initialize` request
- [ ] All tools execute correctly in MCP Inspector
- [ ] `.vscode/mcp.json` is valid JSON with the new server entry
- [ ] §13 Available servers table is updated
