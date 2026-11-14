#!/usr/bin/env node --experimental-strip-types

import fs from "node:fs";
import path from "node:path";
import { parse } from "./sysml/parser.ts";

const NODE_BUDGET = 20;

interface MarkdownImage {
  alt: string;
  href: string;
  line: number;
}

function findFiles(directory: string, extensions: readonly string[]): string[] {
  return fs.readdirSync(directory, { withFileTypes: true }).flatMap((entry) => {
    const absolutePath = path.join(directory, entry.name);
    if (entry.isDirectory()) return findFiles(absolutePath, extensions);
    return entry.isFile() && extensions.some((extension) => entry.name.endsWith(extension))
      ? [absolutePath]
      : [];
  });
}

function parseImages(markdown: string): MarkdownImage[] {
  const images: MarkdownImage[] = [];
  let index = 0;

  while (index < markdown.length - 2) {
    if (markdown[index] !== "!" || markdown[index + 1] !== "[") {
      index++;
      continue;
    }

    const altStart = index + 2;
    let cursor = altStart;
    while (cursor < markdown.length) {
      if (markdown[cursor] === "\\") {
        cursor += 2;
        continue;
      }
      if (markdown[cursor] === "]") break;
      cursor++;
    }
    if (cursor >= markdown.length || markdown[cursor + 1] !== "(") {
      index = altStart;
      continue;
    }

    const hrefStart = cursor + 2;
    const hrefEnd = markdown.indexOf(")", hrefStart);
    if (hrefEnd < 0) break;

    const alt = markdown.slice(altStart, cursor).replace(/\\(.)/g, "$1");
    const href = markdown.slice(hrefStart, hrefEnd).trim().replace(/^<|>$/g, "");
    const line = markdown.slice(0, index).split("\n").length;
    if (href.toLowerCase().split(/[?#]/, 1)[0].endsWith(".svg")) {
      images.push({ alt, href, line });
    }
    index = hrefEnd + 1;
  }

  return images;
}

function nodeCount(model: ReturnType<typeof parse>): number | undefined {
  const diagram = model.diagram;
  if (diagram.diagType === "activity") {
    const definition = model.packages
      .flatMap((pkg) => pkg.activityDefs)
      .find((candidate) => candidate.name === diagram.render);
    return definition
      ? definition.actions.length +
          definition.objects.length +
          definition.decisions.length +
          definition.merges.length +
          definition.notes.length
      : undefined;
  }

  const definition = model.packages
    .flatMap((pkg) => pkg.partDefs)
    .find((candidate) => candidate.name === diagram.render);
  return definition ? definition.parts.length + definition.notes.length : undefined;
}

const repoRoot = path.resolve(process.argv[2] ?? path.join(import.meta.dirname, ".."));
const docsRoot = path.join(repoRoot, "docs");
const sourceFiles = findFiles(docsRoot, [".sysml", ".d2"]);
const sysmlFiles = sourceFiles.filter((file) => file.endsWith(".sysml"));
const svgFiles = findFiles(docsRoot, [".svg"]);
const markdownFiles = findFiles(docsRoot, [".md"]);
const errors: string[] = [];
const referencedSvgs = new Set<string>();
const sourceBySvg = new Map(
  sourceFiles.map((source) => [source.replace(/\.(sysml|d2)$/, ".svg"), source]),
);

for (const source of sysmlFiles) {
  const relativeSource = path.relative(repoRoot, source);
  const svg = source.replace(/\.sysml$/, ".svg");
  if (!fs.existsSync(svg)) errors.push(`${relativeSource}: missing sibling SVG`);

  try {
    const model = parse(fs.readFileSync(source, "utf8"));
    const views = model.packages.flatMap((pkg) => pkg.views);
    if (views.length !== 1) {
      errors.push(`${relativeSource}: expected exactly one view, found ${views.length}`);
      continue;
    }
    if (!model.diagram.title?.trim()) {
      errors.push(`${relativeSource}: view documentation must provide a title`);
    }
    const count = nodeCount(model);
    if (count === undefined) {
      errors.push(`${relativeSource}: exposed definition was not found`);
    } else if (count > NODE_BUDGET) {
      errors.push(
        `${relativeSource}: ${count} rendered nodes exceeds the budget of ${NODE_BUDGET}`,
      );
    }
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    errors.push(`${relativeSource}: failed to parse SysML source: ${message}`);
  }
}

for (const markdown of markdownFiles) {
  const relativeMarkdown = path.relative(repoRoot, markdown);
  const contents = fs.readFileSync(markdown, "utf8");
  for (const image of parseImages(contents)) {
    const imagePath = path.resolve(path.dirname(markdown), image.href);
    const relativeImage = path.relative(repoRoot, imagePath);
    const location = `${relativeMarkdown}:${image.line}`;

    if (!image.alt.trim()) errors.push(`${location}: SVG image alt text must not be empty`);
    if (!fs.existsSync(imagePath)) {
      errors.push(`${location}: referenced SVG does not exist: ${image.href}`);
      continue;
    }
    if (!sourceBySvg.has(imagePath)) {
      errors.push(`${location}: SVG has no sibling .sysml or .d2 source: ${relativeImage}`);
      continue;
    }
    referencedSvgs.add(imagePath);

    const source = sourceBySvg.get(imagePath)!;
    if (source.endsWith(".sysml")) {
      try {
        const title = parse(fs.readFileSync(source, "utf8")).diagram.title?.trim();
        if (title && image.alt.trim() !== title) {
          errors.push(
            `${location}: alt text must match view documentation in ${path.relative(repoRoot, source)}`,
          );
        }
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        errors.push(`${location}: failed to parse source: ${message}`);
      }
    }
  }
}

for (const svg of svgFiles) {
  const relativeSvg = path.relative(repoRoot, svg);
  if (!sourceBySvg.has(svg)) errors.push(`${relativeSvg}: orphan SVG has no source`);
  if (!referencedSvgs.has(svg)) errors.push(`${relativeSvg}: orphan SVG is not embedded in Markdown`);
}

if (errors.length > 0) {
  console.error(`Diagram lint failed with ${errors.length} error(s):`);
  errors.forEach((error) => console.error(`  ${error}`));
  process.exitCode = 1;
} else {
  console.log(
    `Diagram lint passed: ${sysmlFiles.length} SysML sources, ${svgFiles.length} SVGs, node budget ${NODE_BUDGET}.`,
  );
}
