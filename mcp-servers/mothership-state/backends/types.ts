/** Shared types for all state backends */

export interface Story {
  id: string;
  title: string;
  type?: "ui" | "api" | "database" | "integration" | "fullstack" | "verification";
  status: "ready" | "in_progress" | "done" | "blocked";
  priority?: number;
  acceptance_criteria?: AcceptanceCriterion[];
  ac?: string[];
  files?: string[];
  verification?: {
    scripts?: string[];
    commands?: string[];
    e2e?: string;
  };
  test_requirements?: {
    unit?: string[];
    integration?: string[];
    e2e?: string[];
  };
  tested?: boolean;
  comments?: { date: string; text: string }[];
}

export interface AcceptanceCriterion {
  criterion: string;
  verify?: string;
}

export interface Checkpoint {
  phase: string;
  project: string;
  branch: string;
  story: string | null;
}

export interface MothershipConfig {
  state: "local" | "trello" | "linear";
  local?: { stories_file?: string };
  trello?: {
    board_id?: string;
    board_name?: string;
    lists?: { ready?: string; in_progress?: string; done?: string };
  };
  linear?: { team?: string; workspace?: string };
  commands?: Record<string, string>;
  branch_prefix?: string;
}

export interface StateBackend {
  getNextStory(): Promise<Story | null>;
  listStories(status?: string): Promise<Story[]>;
  createStory(story: Partial<Story>): Promise<Story>;
  moveStory(id: string, status: string): Promise<void>;
  completeStory(id: string, report?: string): Promise<void>;
  markTested(id: string): Promise<void>;
}
