import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

import { JSDOM } from "jsdom";
import { Resvg } from "@resvg/resvg-js";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const repoRoot = path.resolve(__dirname, "../..");
const mermaidDir = path.join(repoRoot, "diagrams", "mermaid");
const exportDir = path.join(repoRoot, "diagrams", "export");
const exportSvgDir = path.join(exportDir, "svg");
const exportPngDir = path.join(exportDir, "png");
const roughShimPath = path.join(
  __dirname,
  "node_modules",
  "roughjs",
  "bin",
  "rough",
);
const openColorPackagePath = path.join(
  __dirname,
  "node_modules",
  "open-color",
  "package.json",
);
const laserPointerPackagePath = path.join(
  __dirname,
  "node_modules",
  "@excalidraw",
  "laser-pointer",
  "package.json",
);

const FONT_SIZE = 20;
const EXPORT_WIDTH = 1600;

const dom = new JSDOM("<!doctype html><html><body></body></html>", {
  pretendToBeVisual: true,
});

global.window = dom.window;
global.document = dom.window.document;
global.DOMParser = dom.window.DOMParser;
global.XMLSerializer = dom.window.XMLSerializer;
global.SVGElement = dom.window.SVGElement;
global.HTMLElement = dom.window.HTMLElement;
global.Image = dom.window.Image;
Object.defineProperty(global, "navigator", {
  value: dom.window.navigator,
  configurable: true,
});

const ensureRoughShim = async () => {
  const shimTargets = [
    "rough",
    "generator",
    "canvas",
    "core",
    "geometry",
    "math",
    "renderer",
    "svg",
  ];
  const fillerTargets = [
    "dashed-filler",
    "dot-filler",
    "filler",
    "filler-interface",
    "hachure-filler",
    "hatch-filler",
    "scan-line-hachure",
    "zigzag-filler",
    "zigzag-line-filler",
  ];
  await Promise.all(
    shimTargets.map(async (name) => {
      const targetPath = path.join(
        __dirname,
        "node_modules",
        "roughjs",
        "bin",
        name,
      );
      const hasDefault = name === "rough";
      const shim = [
        `export * from './${name}.js';`,
        ...(hasDefault ? [`export { default } from './${name}.js';`] : []),
        "",
      ].join("\n");
      await fs.writeFile(targetPath, shim, "utf8");
    }),
  );
  await Promise.all(
    fillerTargets.map(async (name) => {
      const targetPath = path.join(
        __dirname,
        "node_modules",
        "roughjs",
        "bin",
        "fillers",
        name,
      );
      const shim = [`export * from './${name}.js';`, ""].join("\n");
      await fs.writeFile(targetPath, shim, "utf8");
    }),
  );
};

const ensureOpenColorShim = async () => {
  try {
    const raw = await fs.readFile(openColorPackagePath, "utf8");
    const pkg = JSON.parse(raw);
    let updated = false;
    if (pkg.main !== "open-color.js") {
      pkg.main = "open-color.js";
      updated = true;
    }
    if (pkg.module !== "open-color.js") {
      pkg.module = "open-color.js";
      updated = true;
    }
    if (updated) {
      await fs.writeFile(
        openColorPackagePath,
        JSON.stringify(pkg, null, 2),
        "utf8",
      );
    }
  } catch (error) {
    console.warn("Unable to update open-color package.json:", error.message);
  }
};

const ensureLaserPointerShim = async () => {
  try {
    const raw = await fs.readFile(laserPointerPackagePath, "utf8");
    const pkg = JSON.parse(raw);
    let updated = false;
    if (pkg.main !== "dist/esm.js") {
      pkg.main = "dist/esm.js";
      updated = true;
    }
    if (pkg.module !== "dist/esm.js") {
      pkg.module = "dist/esm.js";
      updated = true;
    }
    if (pkg.type !== "module") {
      pkg.type = "module";
      updated = true;
    }
    if (updated) {
      await fs.writeFile(
        laserPointerPackagePath,
        JSON.stringify(pkg, null, 2),
        "utf8",
      );
    }
  } catch (error) {
    console.warn("Unable to update @excalidraw/laser-pointer:", error.message);
  }
};

let excalidrawCache = null;
let mermaidCache = null;
let utilsCache = null;

const loadExcalidraw = async () => {
  if (excalidrawCache) {
    return excalidrawCache;
  }
  await ensureRoughShim();
  await ensureOpenColorShim();
  await ensureLaserPointerShim();
  const excalidraw = await import("@excalidraw/excalidraw");
  excalidrawCache = {
    convertToExcalidrawElements: excalidraw.convertToExcalidrawElements,
    getDefaultAppState: excalidraw.getDefaultAppState,
  };
  return excalidrawCache;
};

const loadMermaid = async () => {
  if (mermaidCache) {
    return mermaidCache;
  }
  mermaidCache = await import("@excalidraw/mermaid-to-excalidraw");
  return mermaidCache;
};

const loadUtils = async () => {
  if (utilsCache) {
    return utilsCache;
  }
  await ensureOpenColorShim();
  utilsCache = await import("@excalidraw/utils");
  return utilsCache;
};

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

const renderDiagram = async (filePath) => {
  const raw = await fs.readFile(filePath, "utf8");
  const { convertToExcalidrawElements, getDefaultAppState } =
    await loadExcalidraw();
  const { parseMermaidToExcalidraw } = await loadMermaid();
  const { exportToSvg } = await loadUtils();
  const appState = {
    ...getDefaultAppState(),
    exportBackground: true,
    viewBackgroundColor: "#ffffff",
  };
  const { elements, files } = await parseMermaidToExcalidraw(raw, {
    fontSize: FONT_SIZE,
  });
  const excalidrawElements = convertToExcalidrawElements(elements);

  const svgElement = await exportToSvg({
    elements: excalidrawElements,
    appState,
    files,
  });

  const svgMarkup = svgElement.outerHTML;
  const baseName = toBaseName(path.basename(filePath));
  const svgPath = path.join(exportSvgDir, `${baseName}.svg`);
  await fs.writeFile(svgPath, svgMarkup, "utf8");

  const resvg = new Resvg(svgMarkup, {
    fitTo: { mode: "width", value: EXPORT_WIDTH },
  });
  const pngData = resvg.render();
  const pngPath = path.join(exportPngDir, `${baseName}.png`);
  await fs.writeFile(pngPath, pngData.asPng());

  return { baseName, svgPath, pngPath };
};

const run = async () => {
  await ensureDirs();
  const files = await listMermaidFiles();
  if (!files.length) {
    console.warn("No Mermaid files found.");
    return;
  }

  let failures = 0;
  for (const filePath of files) {
    try {
      const result = await renderDiagram(filePath);
      console.info(`Rendered ${result.baseName}`);
    } catch (error) {
      failures += 1;
      console.error(`Failed ${path.basename(filePath)}:`, error.message);
      if (error.stack) {
        console.error(error.stack);
      }
    }
  }

  if (failures) {
    process.exitCode = 1;
  }
};

run();
