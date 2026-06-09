import { readFileSync, writeFileSync, existsSync } from "fs";
import { join } from "path";
import type { StateBackend, Story, MothershipConfig } from "./types.js";

export class LocalBackend implements StateBackend {
  private storiesPath: string;

  constructor(private projectRoot: string, config: MothershipConfig) {
    const file = config.local?.stories_file ?? "stories.json";
    this.storiesPath = join(projectRoot, ".mothership", file);
  }

  private readData(): { project?: string; branch?: string; stories: Story[] } {
    if (!existsSync(this.storiesPath)) {
      return { stories: [] };
    }
    return JSON.parse(readFileSync(this.storiesPath, "utf-8"));
  }

  private writeData(data: { project?: string; branch?: string; stories: Story[] }): void {
    writeFileSync(this.storiesPath, JSON.stringify(data, null, 2) + "\n", "utf-8");
  }

  async getNextStory(): Promise<Story | null> {
    const data = this.readData();
    // Prefer in_progress, then ready
    const inProgress = data.stories.find((s) => s.status === "in_progress");
    if (inProgress) return inProgress;
    const ready = data.stories.find((s) => s.status === "ready");
    return ready ?? null;
  }

  async listStories(status?: string): Promise<Story[]> {
    const data = this.readData();
    if (!status) return data.stories;
    return data.stories.filter((s) => s.status === status);
  }

  async createStory(story: Partial<Story>): Promise<Story> {
    const data = this.readData();
    const newStory: Story = {
      id: story.id ?? `STORY-${String(data.stories.length + 1).padStart(3, "0")}`,
      title: story.title ?? "Untitled story",
      type: story.type,
      status: story.status ?? "ready",
      priority: story.priority,
      acceptance_criteria: story.acceptance_criteria,
      ac: story.ac,
      files: story.files,
      verification: story.verification,
      test_requirements: story.test_requirements,
    };
    data.stories.push(newStory);
    this.writeData(data);
    return newStory;
  }

  async moveStory(id: string, status: string): Promise<void> {
    const data = this.readData();
    const story = data.stories.find((s) => s.id === id);
    if (!story) throw new Error(`Story ${id} not found`);
    story.status = status as Story["status"];
    this.writeData(data);
  }

  async completeStory(id: string, report?: string): Promise<void> {
    const data = this.readData();
    const story = data.stories.find((s) => s.id === id);
    if (!story) throw new Error(`Story ${id} not found`);
    story.status = "done";
    if (report) {
      if (!story.comments) story.comments = [];
      story.comments.push({ date: new Date().toISOString().split("T")[0], text: report });
    }
    this.writeData(data);
  }

  async markTested(id: string): Promise<void> {
    const data = this.readData();
    const story = data.stories.find((s) => s.id === id);
    if (!story) throw new Error(`Story ${id} not found`);
    story.tested = true;
    this.writeData(data);
  }
}
