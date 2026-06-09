#!/usr/bin/env npx tsx
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";
import { readFileSync, writeFileSync, existsSync, appendFileSync, statSync } from "fs";
import { join } from "path";
import type { MothershipConfig, Checkpoint, StateBackend } from "./backends/types.js";
import { LocalBackend } from "./backends/local.js";
import { TrelloBackend } from "./backends/trello.js";
import { LinearBackend } from "./backends/linear.js";

// Resolve project root: use MOTHERSHIP_PROJECT_ROOT env var or walk up from cwd
function findProjectRoot(): string {
  if (process.env.MOTHERSHIP_PROJECT_ROOT) return process.env.MOTHERSHIP_PROJECT_ROOT;
  let dir = process.cwd();
  while (dir !== "/") {
    if (existsSync(join(dir, ".mothership"))) return dir;
    dir = join(dir, "..");
  }
  return process.cwd();
}

const PROJECT_ROOT = findProjectRoot();
const MOTHERSHIP_DIR = join(PROJECT_ROOT, ".mothership");
const CONFIG_PATH = join(MOTHERSHIP_DIR, "config.json");
const CHECKPOINT_PATH = join(MOTHERSHIP_DIR, "checkpoint.md");
const PROGRESS_PATH = join(MOTHERSHIP_DIR, "progress.md");

function readConfig(): MothershipConfig {
  if (!existsSync(CONFIG_PATH)) {
    return { state: "local", local: { stories_file: "stories.json" } };
  }
  return JSON.parse(readFileSync(CONFIG_PATH, "utf-8"));
}

function writeConfig(config: MothershipConfig): void {
  writeFileSync(CONFIG_PATH, JSON.stringify(config, null, 2) + "\n", "utf-8");
}

function readCheckpoint(): Checkpoint {
  if (!existsSync(CHECKPOINT_PATH)) {
    return { phase: "plan", project: "", branch: "", story: null };
  }
  const text = readFileSync(CHECKPOINT_PATH, "utf-8");
  const cp: Checkpoint = { phase: "plan", project: "", branch: "", story: null };
  for (const line of text.split("\n")) {
    const match = line.match(/^(\w+):\s*(.+)$/);
    if (match) {
      const [, key, value] = match;
      const v = value.trim() === "null" ? null : value.trim();
      if (key === "phase") cp.phase = v ?? "plan";
      else if (key === "project") cp.project = v ?? "";
      else if (key === "branch") cp.branch = v ?? "";
      else if (key === "story") cp.story = v;
    }
  }
  return cp;
}

function writeCheckpoint(cp: Checkpoint): void {
  const text = `phase: ${cp.phase}\nproject: ${cp.project}\nbranch: ${cp.branch}\nstory: ${cp.story ?? "null"}\n`;
  writeFileSync(CHECKPOINT_PATH, text, "utf-8");
}

function getBackend(config: MothershipConfig): StateBackend {
  switch (config.state) {
    case "trello":
      return new TrelloBackend(config);
    case "linear":
      return new LinearBackend(config);
    case "local":
    default:
      return new LocalBackend(PROJECT_ROOT, config);
  }
}

function rotateProgress(): void {
  if (!existsSync(PROGRESS_PATH)) return;
  const stat = statSync(PROGRESS_PATH);
  const lines = readFileSync(PROGRESS_PATH, "utf-8").split("\n");
  if (lines.length > 500) {
    const archivePath = join(MOTHERSHIP_DIR, `progress-${new Date().toISOString().split("T")[0]}.md`);
    writeFileSync(archivePath, lines.slice(0, lines.length - 200).join("\n"), "utf-8");
    writeFileSync(PROGRESS_PATH, lines.slice(lines.length - 200).join("\n"), "utf-8");
  }
}

// --- MCP Server ---

const server = new McpServer({
  name: "mothership-state",
  version: "1.0.0",
});

// Tool: get_config
server.tool("get_config", "Read .mothership/config.json — returns backend type and settings", {}, async () => {
  const config = readConfig();
  return { content: [{ type: "text", text: JSON.stringify(config, null, 2) }] };
});

// Tool: get_checkpoint
server.tool("get_checkpoint", "Return current phase, project, branch, and story", {}, async () => {
  const cp = readCheckpoint();
  return { content: [{ type: "text", text: JSON.stringify(cp, null, 2) }] };
});

// Tool: set_checkpoint
server.tool(
  "set_checkpoint",
  "Update checkpoint atomically",
  {
    phase: z.string().optional().describe("Current phase: plan, build, test, review, deploy, done"),
    project: z.string().optional().describe("Project name"),
    branch: z.string().optional().describe("Git branch"),
    story: z.string().nullable().optional().describe("Current story ID or null"),
  },
  async (args) => {
    const cp = readCheckpoint();
    if (args.phase !== undefined) cp.phase = args.phase;
    if (args.project !== undefined) cp.project = args.project;
    if (args.branch !== undefined) cp.branch = args.branch;
    if (args.story !== undefined) cp.story = args.story;
    writeCheckpoint(cp);
    return { content: [{ type: "text", text: JSON.stringify(cp, null, 2) }] };
  }
);

// Tool: get_next_story
server.tool("get_next_story", "Get the next ready story from the active backend (Trello/Linear/local)", {}, async () => {
  const config = readConfig();
  const backend = getBackend(config);
  const story = await backend.getNextStory();
  if (!story) {
    return { content: [{ type: "text", text: JSON.stringify({ result: "no_stories", message: "No ready stories found" }) }] };
  }
  return { content: [{ type: "text", text: JSON.stringify(story, null, 2) }] };
});

// Tool: list_stories
server.tool(
  "list_stories",
  "List stories filtered by status across any backend",
  { status: z.string().optional().describe("Filter by status: ready, in_progress, done, blocked. Omit for all.") },
  async (args) => {
    const config = readConfig();
    const backend = getBackend(config);
    const stories = await backend.listStories(args.status);
    return { content: [{ type: "text", text: JSON.stringify(stories, null, 2) }] };
  }
);

// Tool: create_story
server.tool(
  "create_story",
  "Create a story (card/issue/JSON entry) with structured description and checklist",
  {
    id: z.string().optional().describe("Story ID (auto-generated if omitted)"),
    title: z.string().describe("Story title — format: 'User can [verb] [noun]'"),
    type: z.enum(["ui", "api", "database", "integration", "fullstack", "verification"]).optional(),
    acceptance_criteria: z
      .array(z.object({ criterion: z.string(), verify: z.string().optional() }))
      .optional()
      .describe("Structured acceptance criteria with optional verify steps"),
    files: z.array(z.string()).optional().describe("Expected file paths"),
    verification_scripts: z.array(z.string()).optional().describe("Verification script names"),
  },
  async (args) => {
    const config = readConfig();
    const backend = getBackend(config);
    const story = await backend.createStory({
      id: args.id,
      title: args.title,
      type: args.type,
      acceptance_criteria: args.acceptance_criteria,
      files: args.files,
      verification: args.verification_scripts ? { scripts: args.verification_scripts } : undefined,
    });
    return { content: [{ type: "text", text: JSON.stringify(story, null, 2) }] };
  }
);

// Tool: move_story
server.tool(
  "move_story",
  "Change story status — moves Trello card between lists, updates JSON status, changes Linear state",
  {
    id: z.string().describe("Story ID"),
    status: z.enum(["ready", "in_progress", "done", "blocked"]).describe("New status"),
  },
  async (args) => {
    const config = readConfig();
    const backend = getBackend(config);
    await backend.moveStory(args.id, args.status);
    return { content: [{ type: "text", text: `Moved ${args.id} to ${args.status}` }] };
  }
);

// Tool: complete_story
server.tool(
  "complete_story",
  "Mark story done and post completion report (Trello comment, JSON update)",
  {
    id: z.string().describe("Story ID"),
    report: z.string().optional().describe("Completion report text"),
  },
  async (args) => {
    const config = readConfig();
    const backend = getBackend(config);
    await backend.completeStory(args.id, args.report);
    return { content: [{ type: "text", text: `Completed ${args.id}` }] };
  }
);

// Tool: mark_tested
server.tool(
  "mark_tested",
  "Add 'tested' label (Trello, auto-creates if missing) or set tested: true (JSON)",
  { id: z.string().describe("Story ID") },
  async (args) => {
    const config = readConfig();
    const backend = getBackend(config);
    await backend.markTested(args.id);
    return { content: [{ type: "text", text: `Marked ${args.id} as tested` }] };
  }
);

// Tool: list_boards (Trello-specific)
server.tool("list_boards", "List available Trello boards for board selection", {}, async () => {
  const config = readConfig();
  if (config.state !== "trello") {
    return { content: [{ type: "text", text: "list_boards is only available with Trello backend" }] };
  }
  const backend = new TrelloBackend(config);
  const boards = await backend.listBoards();
  return { content: [{ type: "text", text: JSON.stringify(boards, null, 2) }] };
});

// Tool: select_board (Trello-specific)
server.tool(
  "select_board",
  "Save Trello board selection to config",
  {
    board_id: z.string().describe("Trello board ID"),
    board_name: z.string().describe("Board name for display"),
  },
  async (args) => {
    const config = readConfig();
    if (!config.trello) config.trello = {};
    config.trello.board_id = args.board_id;
    config.trello.board_name = args.board_name;
    config.state = "trello";
    writeConfig(config);
    return { content: [{ type: "text", text: `Selected board: ${args.board_name} (${args.board_id})` }] };
  }
);

// Tool: log_progress
server.tool(
  "log_progress",
  "Append structured entry to progress.md (with rotation at 500 lines)",
  {
    phase: z.string().describe("Current phase"),
    action: z.string().describe("What was done"),
    story_id: z.string().optional().describe("Related story ID"),
    details: z.string().optional().describe("Additional details"),
  },
  async (args) => {
    rotateProgress();
    const timestamp = new Date().toISOString();
    const entry = [
      `### ${timestamp}`,
      `**Phase:** ${args.phase}`,
      args.story_id ? `**Story:** ${args.story_id}` : null,
      `**Action:** ${args.action}`,
      args.details ? `${args.details}` : null,
      "",
    ]
      .filter(Boolean)
      .join("\n");

    appendFileSync(PROGRESS_PATH, entry + "\n", "utf-8");
    return { content: [{ type: "text", text: `Logged: ${args.action}` }] };
  }
);

// Start server
async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
}

main().catch((err) => {
  console.error("Mothership MCP server failed to start:", err);
  process.exit(1);
});
