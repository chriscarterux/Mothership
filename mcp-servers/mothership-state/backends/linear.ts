import { execSync } from "child_process";
import type { StateBackend, Story, MothershipConfig } from "./types.js";

const LINEAR_API = "https://api.linear.app/graphql";

export class LinearBackend implements StateBackend {
  private apiKey: string;
  private team: string;
  private useCli: boolean;

  constructor(config: MothershipConfig) {
    this.apiKey = process.env.LINEAR_API_KEY ?? "";
    this.team = config.linear?.team ?? "ENG";

    // Prefer CLI if available, fall back to API
    try {
      execSync("linear whoami", { stdio: "pipe" });
      this.useCli = true;
    } catch {
      this.useCli = false;
      if (!this.apiKey) {
        throw new Error("LINEAR_API_KEY must be set or Linear CLI must be authenticated");
      }
    }
  }

  private async graphql(query: string, variables?: Record<string, unknown>): Promise<unknown> {
    const res = await fetch(LINEAR_API, {
      method: "POST",
      headers: {
        Authorization: this.apiKey,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ query, variables }),
    });
    if (!res.ok) throw new Error(`Linear API error: ${res.status}`);
    const json = (await res.json()) as { data: unknown; errors?: { message: string }[] };
    if (json.errors?.length) throw new Error(json.errors[0].message);
    return json.data;
  }

  async getNextStory(): Promise<Story | null> {
    if (this.useCli) {
      try {
        const output = execSync(`linear issue list --team ${this.team} --state "Ready" --limit 1 --json`, {
          encoding: "utf-8",
          stdio: ["pipe", "pipe", "pipe"],
        });
        const issues = JSON.parse(output);
        if (!issues.length) return null;
        const issue = issues[0];
        return {
          id: issue.identifier,
          title: issue.title,
          status: "ready",
          ac: issue.description ? this.parseAc(issue.description) : [],
        };
      } catch {
        return null;
      }
    }

    const data = (await this.graphql(`
      query($teamKey: String!) {
        issues(filter: { team: { key: { eq: $teamKey } }, state: { name: { eq: "Ready" } } }, first: 1, orderBy: priority) {
          nodes { id identifier title description }
        }
      }
    `, { teamKey: this.team })) as { issues: { nodes: { id: string; identifier: string; title: string; description: string }[] } };

    if (!data.issues.nodes.length) return null;
    const issue = data.issues.nodes[0];
    return {
      id: issue.identifier,
      title: issue.title,
      status: "ready",
      ac: this.parseAc(issue.description),
    };
  }

  async listStories(status?: string): Promise<Story[]> {
    const stateMap: Record<string, string> = {
      ready: "Ready",
      in_progress: "In Progress",
      done: "Done",
      blocked: "Blocked",
    };

    const stateFilter = status && stateMap[status]
      ? `state: { name: { eq: "${stateMap[status]}" } },`
      : "";

    const data = (await this.graphql(`
      query($teamKey: String!) {
        issues(filter: { team: { key: { eq: $teamKey } }, ${stateFilter} }, first: 50, orderBy: priority) {
          nodes { id identifier title description state { name } }
        }
      }
    `, { teamKey: this.team })) as { issues: { nodes: { identifier: string; title: string; description: string; state: { name: string } }[] } };

    const reverseMap: Record<string, Story["status"]> = {
      Ready: "ready",
      Backlog: "ready",
      "In Progress": "in_progress",
      Done: "done",
      Completed: "done",
      Blocked: "blocked",
    };

    return data.issues.nodes.map((issue) => ({
      id: issue.identifier,
      title: issue.title,
      status: reverseMap[issue.state.name] ?? "ready",
      ac: this.parseAc(issue.description),
    }));
  }

  async createStory(story: Partial<Story>): Promise<Story> {
    if (this.useCli) {
      const desc = this.buildDescription(story);
      const cmd = `linear issue create --team ${this.team} --title "${(story.title ?? "Untitled").replace(/"/g, '\\"')}" --description "${desc.replace(/"/g, '\\"')}" --state "Ready"`;
      const output = execSync(cmd, { encoding: "utf-8" });
      const idMatch = output.match(/([A-Z]+-\d+)/);
      return {
        id: idMatch?.[1] ?? story.id ?? "UNKNOWN",
        title: story.title ?? "Untitled",
        status: "ready",
        ...story,
      } as Story;
    }

    // Get team ID and ready state ID
    const teamData = (await this.graphql(`
      query($teamKey: String!) {
        teams(filter: { key: { eq: $teamKey } }) {
          nodes { id states { nodes { id name } } }
        }
      }
    `, { teamKey: this.team })) as { teams: { nodes: { id: string; states: { nodes: { id: string; name: string }[] } }[] } };

    const teamNode = teamData.teams.nodes[0];
    if (!teamNode) throw new Error(`Team ${this.team} not found`);
    const readyState = teamNode.states.nodes.find((s) => s.name === "Ready");

    const desc = this.buildDescription(story);
    const data = (await this.graphql(`
      mutation($input: IssueCreateInput!) {
        issueCreate(input: $input) { issue { id identifier title } }
      }
    `, {
      input: {
        teamId: teamNode.id,
        title: story.title ?? "Untitled",
        description: desc,
        stateId: readyState?.id,
      },
    })) as { issueCreate: { issue: { identifier: string; title: string } } };

    return {
      id: data.issueCreate.issue.identifier,
      title: data.issueCreate.issue.title,
      status: "ready",
      ...story,
    } as Story;
  }

  async moveStory(id: string, status: string): Promise<void> {
    const stateMap: Record<string, string> = {
      ready: "Ready",
      in_progress: "In Progress",
      done: "Done",
      blocked: "Blocked",
    };

    if (this.useCli) {
      execSync(`linear issue update ${id} --state "${stateMap[status] ?? status}"`, { stdio: "pipe" });
      return;
    }

    // Resolve via API
    const issueData = (await this.graphql(`
      query($id: String!) {
        issueVcsByIdentifier: issue(id: $id) { id team { states { nodes { id name } } } }
      }
    `.replace("issueVcsByIdentifier: issue(id: $id)", `issue(id: "${id}")`))) as { issue: { id: string; team: { states: { nodes: { id: string; name: string }[] } } } };

    const targetState = issueData.issue.team.states.nodes.find((s) => s.name === (stateMap[status] ?? status));
    if (!targetState) throw new Error(`State ${status} not found`);

    await this.graphql(`
      mutation { issueUpdate(id: "${issueData.issue.id}", input: { stateId: "${targetState.id}" }) { issue { id } } }
    `);
  }

  async completeStory(id: string, report?: string): Promise<void> {
    await this.moveStory(id, "done");
    if (report && this.useCli) {
      execSync(`linear comment create ${id} --body "${report.replace(/"/g, '\\"')}"`, { stdio: "pipe" });
    }
  }

  async markTested(id: string): Promise<void> {
    if (this.useCli) {
      execSync(`linear issue update ${id} --label "tested"`, { stdio: "pipe" });
      return;
    }
    // API label addition would require label ID lookup — simplified
    await this.graphql(`
      mutation { issueUpdate(id: "${id}", input: { }) { issue { id } } }
    `);
  }

  private parseAc(desc: string): string[] {
    if (!desc) return [];
    const lines = desc.split("\n");
    const ac: string[] = [];
    let inAc = false;
    for (const line of lines) {
      if (line.match(/^##?\s*AC|^##?\s*Acceptance Criteria/i)) { inAc = true; continue; }
      if (line.match(/^##?\s/) && inAc) break;
      if (inAc && line.match(/^-\s/)) {
        ac.push(line.replace(/^-\s*(\[[ x]\]\s*)?/, "").trim());
      }
    }
    return ac;
  }

  private buildDescription(story: Partial<Story>): string {
    const sections: string[] = [];
    if (story.ac?.length) {
      sections.push("## AC");
      for (const ac of story.ac) sections.push(`- [ ] ${ac}`);
    } else if (story.acceptance_criteria?.length) {
      sections.push("## Acceptance Criteria");
      for (const ac of story.acceptance_criteria) sections.push(`- [ ] ${ac.criterion}`);
    }
    if (story.files?.length) {
      sections.push("\n## Files");
      for (const f of story.files) sections.push(`- ${f}`);
    }
    return sections.join("\n");
  }
}
