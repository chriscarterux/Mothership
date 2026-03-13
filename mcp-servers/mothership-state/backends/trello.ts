import type { StateBackend, Story, MothershipConfig } from "./types.js";

const TRELLO_API = "https://api.trello.com/1";

export class TrelloBackend implements StateBackend {
  private apiKey: string;
  private token: string;
  private boardId: string;
  private listNames: { ready: string; in_progress: string; done: string };
  private listIds: Record<string, string> = {};

  constructor(config: MothershipConfig) {
    this.apiKey = process.env.TRELLO_API_KEY ?? "";
    this.token = process.env.TRELLO_TOKEN ?? "";
    if (!this.apiKey || !this.token) {
      throw new Error("TRELLO_API_KEY and TRELLO_TOKEN must be set");
    }
    this.boardId = config.trello?.board_id ?? "";
    this.listNames = {
      ready: config.trello?.lists?.ready ?? "Backlog",
      in_progress: config.trello?.lists?.in_progress ?? "Active Request",
      done: config.trello?.lists?.done ?? "Approved",
    };
  }

  private authParams(): string {
    return `key=${this.apiKey}&token=${this.token}`;
  }

  private async api(path: string, options?: RequestInit): Promise<unknown> {
    const sep = path.includes("?") ? "&" : "?";
    const url = `${TRELLO_API}${path}${sep}${this.authParams()}`;
    const res = await fetch(url, options);
    if (!res.ok) {
      const text = await res.text();
      throw new Error(`Trello API error ${res.status}: ${text}`);
    }
    return res.json();
  }

  private async ensureListIds(): Promise<void> {
    if (Object.keys(this.listIds).length > 0) return;
    if (!this.boardId) throw new Error("No board_id configured. Run select_board first.");
    const lists = (await this.api(`/boards/${this.boardId}/lists`)) as { id: string; name: string }[];
    for (const list of lists) {
      if (list.name === this.listNames.ready) this.listIds.ready = list.id;
      if (list.name === this.listNames.in_progress) this.listIds.in_progress = list.id;
      if (list.name === this.listNames.done) this.listIds.done = list.id;
    }
  }

  private cardToStory(card: Record<string, unknown>): Story {
    const name = card.name as string;
    const idMatch = name.match(/^([A-Z]+-\d+):\s*/);
    return {
      id: idMatch ? idMatch[1] : (card.id as string),
      title: idMatch ? name.replace(idMatch[0], "") : name,
      status: "ready",
      ac: this.parseAcFromDesc(card.desc as string),
      files: this.parseFilesFromDesc(card.desc as string),
    };
  }

  private parseAcFromDesc(desc: string): string[] {
    const lines = desc.split("\n");
    const ac: string[] = [];
    let inAc = false;
    for (const line of lines) {
      if (line.match(/^##\s*Acceptance Criteria/i)) { inAc = true; continue; }
      if (line.match(/^##\s/) && inAc) break;
      if (inAc && line.match(/^-\s*\[[ x]\]/)) {
        ac.push(line.replace(/^-\s*\[[ x]\]\s*/, "").trim());
      }
    }
    return ac;
  }

  private parseFilesFromDesc(desc: string): string[] {
    const lines = desc.split("\n");
    const files: string[] = [];
    let inFiles = false;
    for (const line of lines) {
      if (line.match(/Files to modify|## Files/i)) { inFiles = true; continue; }
      if (line.match(/^##\s/) && inFiles) break;
      if (inFiles && line.match(/^-\s/)) {
        files.push(line.replace(/^-\s*\*?\*?/, "").replace(/\*?\*?\s*$/, "").trim());
      }
    }
    return files;
  }

  async getNextStory(): Promise<Story | null> {
    await this.ensureListIds();
    if (!this.listIds.ready) return null;
    const cards = (await this.api(`/lists/${this.listIds.ready}/cards?fields=name,desc,labels`)) as Record<string, unknown>[];
    if (!cards.length) return null;
    return this.cardToStory(cards[0]);
  }

  async listStories(status?: string): Promise<Story[]> {
    await this.ensureListIds();
    const statusToList: Record<string, string> = {
      ready: this.listIds.ready,
      in_progress: this.listIds.in_progress,
      done: this.listIds.done,
    };

    if (status && statusToList[status]) {
      const cards = (await this.api(`/lists/${statusToList[status]}/cards?fields=name,desc,labels`)) as Record<string, unknown>[];
      return cards.map((c) => ({ ...this.cardToStory(c), status: status as Story["status"] }));
    }

    // All stories across all lists
    const cards = (await this.api(`/boards/${this.boardId}/cards?fields=name,desc,idList,labels`)) as Record<string, unknown>[];
    return cards.map((c) => {
      const story = this.cardToStory(c);
      const idList = c.idList as string;
      if (idList === this.listIds.ready) story.status = "ready";
      else if (idList === this.listIds.in_progress) story.status = "in_progress";
      else if (idList === this.listIds.done) story.status = "done";
      return story;
    });
  }

  async createStory(story: Partial<Story>): Promise<Story> {
    await this.ensureListIds();
    const desc = this.buildCardDesc(story);
    const body = new URLSearchParams({
      key: this.apiKey,
      token: this.token,
      idList: this.listIds.ready,
      name: story.id ? `${story.id}: ${story.title}` : (story.title ?? "Untitled"),
      desc,
    });

    const card = (await fetch(`${TRELLO_API}/cards`, {
      method: "POST",
      body,
    }).then((r) => r.json())) as Record<string, unknown>;

    // Add checklist for AC
    if (story.acceptance_criteria?.length || story.ac?.length) {
      const checklist = (await fetch(`${TRELLO_API}/checklists?${this.authParams()}`, {
        method: "POST",
        headers: { "Content-Type": "application/x-www-form-urlencoded" },
        body: new URLSearchParams({ idCard: card.id as string, name: "Acceptance Criteria" }),
      }).then((r) => r.json())) as Record<string, unknown>;

      const items = story.acceptance_criteria?.map((a) => a.criterion) ?? story.ac ?? [];
      for (const item of items) {
        await fetch(`${TRELLO_API}/checklists/${checklist.id}/checkItems?${this.authParams()}`, {
          method: "POST",
          headers: { "Content-Type": "application/x-www-form-urlencoded" },
          body: new URLSearchParams({ name: item }),
        });
      }
    }

    return {
      id: story.id ?? (card.id as string),
      title: story.title ?? "Untitled",
      status: "ready",
      ...story,
    } as Story;
  }

  private buildCardDesc(story: Partial<Story>): string {
    const sections: string[] = [];
    if (story.acceptance_criteria?.length) {
      sections.push("## Acceptance Criteria");
      for (const ac of story.acceptance_criteria) {
        sections.push(`- [ ] ${ac.criterion}`);
        if (ac.verify) sections.push(`  verify: ${ac.verify}`);
      }
    } else if (story.ac?.length) {
      sections.push("## Acceptance Criteria");
      for (const ac of story.ac) sections.push(`- [ ] ${ac}`);
    }
    if (story.files?.length) {
      sections.push("\n## Technical Context");
      sections.push(`**Files to modify:** ${story.files.join(", ")}`);
    }
    if (story.verification?.scripts?.length) {
      sections.push("\n## Verification");
      sections.push(`Scripts: ${story.verification.scripts.join(", ")}`);
    }
    return sections.join("\n");
  }

  async moveStory(id: string, status: string): Promise<void> {
    await this.ensureListIds();
    const statusToList: Record<string, string> = {
      ready: this.listIds.ready,
      in_progress: this.listIds.in_progress,
      done: this.listIds.done,
    };
    const listId = statusToList[status];
    if (!listId) throw new Error(`Unknown status: ${status}`);

    // id could be story ID (from card name) or card ID — find the card
    const cardId = await this.resolveCardId(id);
    await this.api(`/cards/${cardId}?idList=${listId}`, { method: "PUT" });
  }

  async completeStory(id: string, report?: string): Promise<void> {
    await this.ensureListIds();
    const cardId = await this.resolveCardId(id);
    // Move to done list
    await this.api(`/cards/${cardId}?idList=${this.listIds.done}`, { method: "PUT" });
    // Post completion comment
    if (report) {
      const body = new URLSearchParams({
        key: this.apiKey,
        token: this.token,
        text: report,
      });
      await fetch(`${TRELLO_API}/cards/${cardId}/actions/comments`, {
        method: "POST",
        body,
      });
    }
  }

  async markTested(id: string): Promise<void> {
    await this.ensureListIds();
    const cardId = await this.resolveCardId(id);

    // Find or create "tested" label
    const labels = (await this.api(`/boards/${this.boardId}/labels`)) as { id: string; name: string }[];
    let testedLabel = labels.find((l) => l.name === "tested");
    if (!testedLabel) {
      testedLabel = (await fetch(`${TRELLO_API}/boards/${this.boardId}/labels?${this.authParams()}`, {
        method: "POST",
        headers: { "Content-Type": "application/x-www-form-urlencoded" },
        body: new URLSearchParams({ name: "tested", color: "green" }),
      }).then((r) => r.json())) as { id: string; name: string };
    }

    // Apply label
    await fetch(`${TRELLO_API}/cards/${cardId}/idLabels?${this.authParams()}`, {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({ value: testedLabel.id }),
    });
  }

  private async resolveCardId(id: string): Promise<string> {
    // If it looks like a Trello card ID (24 hex chars), use directly
    if (/^[0-9a-f]{24}$/.test(id)) return id;
    // Search board cards for matching story ID prefix
    const cards = (await this.api(`/boards/${this.boardId}/cards?fields=name`)) as { id: string; name: string }[];
    const match = cards.find((c) => c.name.startsWith(`${id}:`));
    if (match) return match.id;
    throw new Error(`Card not found for story: ${id}`);
  }

  // Trello-specific: list boards
  async listBoards(): Promise<{ id: string; name: string; url: string }[]> {
    const boards = (await this.api("/members/me/boards?fields=name,url")) as { id: string; name: string; url: string }[];
    return boards;
  }

  // Trello-specific: validate board
  async validateBoard(boardId: string): Promise<string | null> {
    try {
      const board = (await this.api(`/boards/${boardId}?fields=name`)) as { name: string };
      return board.name;
    } catch {
      return null;
    }
  }
}
