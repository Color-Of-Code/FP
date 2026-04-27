/**
 * Top-level orchestrator: selects the correct diagram renderer based on the
 * diagram type declared in the model's #diagram block, then draws it into a
 * jsdom-backed SVG document using D3.
 */

import { type Model } from "../types.ts";
import { renderActivity } from "./activity.ts";
import { renderIbd } from "./ibd.ts";
import { appendStatusMessage, createSvgDocument } from "./title.ts";

/**
 * Convert a parsed SysML v2 model to a standalone SVG string.
 * `baseName` is used as a fallback title when the model has none.
 */
export async function modelToSvg(model: Model, baseName: string): Promise<string> {
  const diag  = model.diagram;
  const title = diag.title ?? baseName;

  if (diag.diagType === "ibd") {
    const allPartDefs = model.packages.flatMap(p => p.partDefs);
    const pd = diag.render
      ? allPartDefs.find(d => d.name === diag.render) ?? allPartDefs[0]
      : allPartDefs[0];
    if (!pd) {
      const doc = createSvgDocument(title, 400, 100);
      appendStatusMessage(doc.content, "No part def found");
      return doc.serialize();
    }
    const plan = renderIbd(pd, diag);
    const doc = createSvgDocument(title, plan.width, plan.height);
    plan.draw(doc.content);
    return doc.serialize();
  }

  // activity (default)
  const allActivityDefs = model.packages.flatMap(p => p.activityDefs);
  const allActionDefs   = new Map(
    model.packages.flatMap(p => p.actionDefs).map(a => [a.name, a])
  );
  const act = diag.render
    ? allActivityDefs.find(d => d.name === diag.render) ?? allActivityDefs[0]
    : allActivityDefs[0];
  if (!act) {
    const doc = createSvgDocument(title, 400, 100);
    appendStatusMessage(doc.content, "No activity def found");
    return doc.serialize();
  }
  const plan = await renderActivity(act, diag, allActionDefs);
  const doc = createSvgDocument(title, plan.width, plan.height);
  plan.draw(doc.content);
  return doc.serialize();
}
