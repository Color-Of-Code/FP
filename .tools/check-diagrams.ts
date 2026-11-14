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
  const imagePattern = /!\[((?:\\.|[^\\\]])*)\]\(([^)]+)\)/g;
  return [...markdown.matchAll(imagePattern)]
    .flatMap((match) => {
      const [alt, href] = match.slice(1);
      if (alt === undefined || href === undefined) return [];
      return [{
        alt: alt.replace(/\\(.)/g, "$1"),
        href: href.trim().replace(/^<|>$/g, ""),
        line: markdown.slice(0, match.index).split("\n").length,
      }];
    })
    .filter((image) => image.href.toLowerCase().split(/[?#]/, 1).at(0)?.endsWith(".svg") ?? false);
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

function checkSysmlSource(repoRoot: string, source: string): string[] {
  const relativeSource = path.relative(repoRoot, source);
  const svg = source.replace(/\.sysml$/, ".svg");
  const missingSvg = fs.existsSync(svg) ? [] : [`${relativeSource}: missing sibling SVG`];

  try {
    const model = parse(fs.readFileSync(source, "utf8"));
    const views = model.packages.flatMap((pkg) => pkg.views);
    if (views.length !== 1) {
      return [
        ...missingSvg,
        `${relativeSource}: expected exactly one view, found ${views.length}`,
      ];
    }

    const count = nodeCount(model);
    return [
      ...missingSvg,
      ...(!model.diagram.title?.trim()
        ? [`${relativeSource}: view documentation must provide a title`]
        : []),
      ...(count === undefined
        ? [`${relativeSource}: exposed definition was not found`]
        : count > NODE_BUDGET
          ? [`${relativeSource}: ${count} rendered nodes exceeds the budget of ${NODE_BUDGET}`]
          : []),
    ];
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return [
      ...missingSvg,
      `${relativeSource}: failed to parse SysML source: ${message}`,
    ];
  }
}

function checkMarkdownImage(
  repoRoot: string,
  markdown: string,
  image: MarkdownImage,
  sourceBySvg: Map<string, string>,
): { errors: string[]; referencedSvg?: string } {
  const relativeMarkdown = path.relative(repoRoot, markdown);
  const imagePath = path.resolve(path.dirname(markdown), image.href);
  const relativeImage = path.relative(repoRoot, imagePath);
  const location = `${relativeMarkdown}:${image.line}`;
  const emptyAlt = image.alt.trim() ? [] : [`${location}: SVG image alt text must not be empty`];

  if (!fs.existsSync(imagePath)) {
    return {
      errors: [...emptyAlt, `${location}: referenced SVG does not exist: ${image.href}`],
    };
  }
  if (!sourceBySvg.has(imagePath)) {
    return {
      errors: [
        ...emptyAlt,
        `${location}: SVG has no sibling .sysml or .d2 source: ${relativeImage}`,
      ],
    };
  }

  const source = sourceBySvg.get(imagePath)!;
  if (!source.endsWith(".sysml")) return { errors: emptyAlt, referencedSvg: imagePath };

  try {
    const title = parse(fs.readFileSync(source, "utf8")).diagram.title?.trim();
    return {
      errors: [
        ...emptyAlt,
        ...(title && image.alt.trim() !== title
          ? [
              `${location}: alt text must match view documentation in ${path.relative(repoRoot, source)}`,
            ]
          : []),
      ],
      referencedSvg: imagePath,
    };
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return {
      errors: [...emptyAlt, `${location}: failed to parse source: ${message}`],
      referencedSvg: imagePath,
    };
  }
}

const repoRoot = path.resolve(process.argv[2] ?? path.join(import.meta.dirname, ".."));
const docsRoot = path.join(repoRoot, "docs");
const sourceFiles = findFiles(docsRoot, [".sysml", ".d2"]);
const sysmlFiles = sourceFiles.filter((file) => file.endsWith(".sysml"));
const svgFiles = findFiles(docsRoot, [".svg"]);
const markdownFiles = findFiles(docsRoot, [".md"]);
const sourceBySvg = new Map(
  sourceFiles.map((source) => [source.replace(/\.(sysml|d2)$/, ".svg"), source]),
);
const sourceErrors = sysmlFiles.flatMap((source) => checkSysmlSource(repoRoot, source));
const markdownResults = markdownFiles.flatMap((markdown) => {
  const contents = fs.readFileSync(markdown, "utf8");
  return parseImages(contents).map((image) =>
    checkMarkdownImage(repoRoot, markdown, image, sourceBySvg),
  );
});
const referencedSvgs = new Set(
  markdownResults.flatMap((result) => (result.referencedSvg ? [result.referencedSvg] : [])),
);
const svgErrors = svgFiles.flatMap((svg) => {
  const relativeSvg = path.relative(repoRoot, svg);
  return [
    ...(!sourceBySvg.has(svg) ? [`${relativeSvg}: orphan SVG has no source`] : []),
    ...(!referencedSvgs.has(svg)
      ? [`${relativeSvg}: orphan SVG is not embedded in Markdown`]
      : []),
  ];
});
const errors = [
  ...sourceErrors,
  ...markdownResults.flatMap((result) => result.errors),
  ...svgErrors,
];

if (errors.length > 0) {
  console.error(`Diagram lint failed with ${errors.length} error(s):`);
  errors.forEach((error) => {
    console.error(`  ${error}`);
  });
  process.exitCode = 1;
} else {
  console.log(
    `Diagram lint passed: ${sysmlFiles.length} SysML sources, ${svgFiles.length} SVGs, node budget ${NODE_BUDGET}.`,
  );
}
