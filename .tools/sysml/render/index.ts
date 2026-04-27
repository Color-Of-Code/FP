/**
 * Top-level orchestrator.
 *
 * Each diagram type is described by a `DiagramRenderer` entry registered in
 * the `renderers` map.  Adding a new diagram type (state machine, sequence,
 * …) means writing a renderer module and adding one entry here — no
 * branches in the dispatcher need to change.
 */

import { type DiagramMeta, type DiagramType, type Model } from "../types.ts";
import { renderActivity } from "./activity.ts";
import { renderIbd } from "./ibd.ts";
import { appendStatusMessage, createSvgDocument, type RenderPlan } from "./title.ts";

interface DiagramRenderer {
  /** Build a render plan for the given model + diagram metadata. */
  plan(model: Model, diag: DiagramMeta): Promise<RenderPlan | null>;
  /** Message displayed when nothing matching is found. */
  notFoundMessage: string;
}

const ibdRenderer: DiagramRenderer = {
  notFoundMessage: "No part def found",
  async plan(model, diag) {
    const all = model.packages.flatMap(p => p.partDefs);
    const pd  = diag.render
      ? all.find(d => d.name === diag.render) ?? all[0]
      : all[0];
    return pd ? renderIbd(pd, diag) : null;
  },
};

const activityRenderer: DiagramRenderer = {
  notFoundMessage: "No activity def found",
  async plan(model, diag) {
    const all = model.packages.flatMap(p => p.activityDefs);
    const act = diag.render
      ? all.find(d => d.name === diag.render) ?? all[0]
      : all[0];
    if (!act) return null;
    const actionDefs = new Map(
      model.packages.flatMap(p => p.actionDefs).map(a => [a.name, a]),
    );
    return renderActivity(act, diag, actionDefs);
  },
};

const renderers: Record<DiagramType, DiagramRenderer> = {
  ibd:      ibdRenderer,
  activity: activityRenderer,
};

/**
 * Convert a parsed SysML v2 model to a standalone SVG string.
 * `baseName` is used as a fallback title when the model has none.
 */
export async function modelToSvg(model: Model, baseName: string): Promise<string> {
  const diag     = model.diagram;
  const title    = diag.title ?? baseName;
  const renderer = renderers[diag.diagType] ?? activityRenderer;
  const plan     = await renderer.plan(model, diag);

  if (!plan) {
    const doc = createSvgDocument(title, 400, 100);
    appendStatusMessage(doc.content, renderer.notFoundMessage);
    return doc.serialize();
  }

  const doc = createSvgDocument(title, plan.width, plan.height);
  plan.draw(doc.content);
  return doc.serialize();
}
