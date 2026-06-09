# Diagram exporter

Batch converts Mermaid diagrams into Excalidraw-style SVG + PNG assets.

## Setup

```bash
cd tools/diagram-export
npm install
```

## Export

```bash
npm run export
```

Outputs:
- `diagrams/export/svg/*.svg`
- `diagrams/export/png/*.png`

## Export (Playwright)

Uses a headless browser to render Excalidraw-style SVGs, then converts to PNG.

```bash
npm run export:playwright
```
