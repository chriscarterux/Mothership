import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

import os from "node:os";
import { chromium } from "playwright";
import { Resvg } from "@resvg/resvg-js";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const repoRoot = path.resolve(__dirname, "../..");
const mermaidDir = path.join(repoRoot, "diagrams", "mermaid");
const exportDir = path.join(repoRoot, "diagrams", "export");
const exportSvgDir = path.join(exportDir, "svg");
const exportPngDir = path.join(exportDir, "png");
const runnerPath = path.join(__dirname, "runner.html");
const exportWidth = 1600;

const toBaseName = (filename) => filename.replace(/\.mmd$/i, "");

const ensureDirs = async () => {
  await fs.mkdir(exportSvgDir, { recursive: true });
  await fs.mkdir(exportPngDir, { recursive: true });
};

const listMermaidFiles = async () => {
  const entries = await fs.readdir(mermaidDir, { withFileTypes: true });
  return entries
    .filter((entry) => entry.isFile() && entry.name.endsWith(".mmd"))
    .map((entry) => path.join(mermaidDir, entry.name));
};

const renderToPng = (svgMarkup) => {
  const resvg = new Resvg(svgMarkup, {
    fitTo: { mode: "width", value: exportWidth },
  });
  return resvg.render().asPng();
};

const resolveChromiumExecutable = async () => {
  const cacheRoot =
    process.env.PLAYWRIGHT_BROWSERS_PATH ||
    path.join(os.homedir(), "Library", "Caches", "ms-playwright");
  try {
    const entries = await fs.readdir(cacheRoot, { withFileTypes: true });
    const headlessDirs = entries
      .filter((entry) => entry.isDirectory())
      .map((entry) => entry.name)
      .filter((name) => name.startsWith("chromium_headless_shell-"))
      .sort((a, b) => {
        const aVer = Number(a.split("-").pop());
        const bVer = Number(b.split("-").pop());
        return bVer - aVer;
      });
    for (const headlessDir of headlessDirs) {
      const candidateDir = path.join(cacheRoot, headlessDir);
      const subdirs = await fs.readdir(candidateDir, { withFileTypes: true });
      const shellDir = subdirs
        .filter((entry) => entry.isDirectory())
        .map((entry) => entry.name)
        .find((name) => name.startsWith("chrome-headless-shell-"));
      if (!shellDir) {
        continue;
      }
      const execPath = path.join(
        candidateDir,
        shellDir,
        "chrome-headless-shell",
      );
      await fs.access(execPath);
      return execPath;
    }
    return null;
  } catch {
    return null;
  }
};

const run = async () => {
  await ensureDirs();
  const files = await listMermaidFiles();
  if (!files.length) {
    console.warn("No Mermaid files found.");
    return;
  }

  const executablePath = await resolveChromiumExecutable();
  const browser = await chromium.launch(
    executablePath ? { executablePath } : undefined,
  );
  const page = await browser.newPage();
  page.on("console", (msg) => {
    console.info(`[browser:${msg.type()}] ${msg.text()}`);
  });
  page.on("pageerror", (error) => {
    console.error("[browser:error]", error.message);
  });
  page.on("requestfailed", (request) => {
    console.error(
      "[browser:requestfailed]",
      request.url(),
      request.failure()?.errorText || "",
    );
  });
  page.on("response", (response) => {
    if (!response.ok()) {
      console.error(
        "[browser:response]",
        response.status(),
        response.url(),
      );
    }
  });
  await page.goto(`file://${runnerPath}`, { waitUntil: "load" });
  await page.waitForFunction(
    () => typeof window.renderMermaidToSvg === "function",
    { timeout: 60000 },
  );

  let failures = 0;
  for (const filePath of files) {
    const baseName = toBaseName(path.basename(filePath));
    try {
      const mermaidText = await fs.readFile(filePath, "utf8");
      const svgMarkup = await page.evaluate(
        async (text) => window.renderMermaidToSvg(text),
        mermaidText,
      );
      const svgPath = path.join(exportSvgDir, `${baseName}.svg`);
      await fs.writeFile(svgPath, svgMarkup, "utf8");

      const pngData = renderToPng(svgMarkup);
      const pngPath = path.join(exportPngDir, `${baseName}.png`);
      await fs.writeFile(pngPath, pngData);

      console.info(`Rendered ${baseName}`);
    } catch (error) {
      failures += 1;
      console.error(`Failed ${baseName}:`, error.message);
    }
  }

  await browser.close();
  if (failures) {
    process.exitCode = 1;
  }
};

run();
