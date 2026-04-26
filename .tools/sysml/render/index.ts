/**
 * Top-level orchestrator: selects the correct diagram renderer based on the
 * diagram type declared in the model's #diagram block, then wraps the result
 * in a complete SVG document.
 */

import { type Model } from "../types.ts";
import { renderActivity } from "./activity.ts";
import { renderIbd } from "./ibd.ts";
import { makeSvg } from "./title.ts";

/**
 * Convert a parsed SysML v2 model to a standalone SVG string.
 * `baseName` is used as a fallback title when the model has none.
 */
export function modelToSvg(model: Model, baseName: string): string {
  const diag  = model.diagram;
  const title = diag.title ?? baseName;

  if (diag.diagType === "ibd") {
    const allPartDefs = model.packages.flatMap(p => p.partDefs);
    const pd = diag.render
      ? allPartDefs.find(d => d.name === diag.render) ?? allPartDefs[0]
      : allPartDefs[0];
    if (!pd) return makeSvg(`<text x="20" y="40" fill="red">No part def found</text>`, title, 400, 100);
    const [inner, W, H] = renderIbd(pd, diag);
    return makeSvg(inner, title, W, H);
  }

  // activity (default)
  const allActivityDefs = model.packages.flatMap(p => p.activityDefs);
  const allActionDefs   = new Map(
    model.packages.flatMap(p => p.actionDefs).map(a => [a.name, a])
  );
  const act = diag.render
    ? allActivityDefs.find(d => d.name === diag.render) ?? allActivityDefs[0]
    : allActivityDefs[0];
  if (!act) return makeSvg(`<text x="20" y="40" fill="red">No activity def found</text>`, title, 400, 100);
  const [inner, W, H] = renderActivity(act, diag, allActionDefs);
  return makeSvg(inner, title, W, H);
}
