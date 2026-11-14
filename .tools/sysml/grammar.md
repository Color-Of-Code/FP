# SysML grammar reference

The local SysML parser implements a deliberately small SysML v2 textual subset plus the FP project's
rendering metadata. The authoritative grammar is [`sysml.langium`](sysml.langium); the project view
and rendering declarations are in [`FpDiagram.sysml`](FpDiagram.sysml). Regenerate parser sources
with `make -C .tools langium-gen`.

This subset supports the syntax currently used by `docs/**/*.sysml`. It is not a full SysML v2
implementation: imports and standard-library names are parsed but not resolved, and an independent
SysML implementation has not been used to validate the sources.

## Supported constructs

- Packages and imports.
- `action def` definitions with pins, actions, items, decisions, merges, and flows.
- `part def` definitions with parts, ports, and connections.
- User-defined metadata definitions and annotations.
- View definitions, view usages, documentation comments, `expose`, and `render`.

The parser does not accept the retired `#diagram` extension or the legacy `activity def`, `object`,
and `decision` keywords. Use `action def`, `item`, and `decide`.

## Project library

[`FpDiagram.sysml`](FpDiagram.sysml) declares `FpActivityView` and `FpIbdView`, which specialize the
standard `ActionFlowView` and `InterconnectionView` concepts, plus the project's `fpActivityDiagram`
and `fpIbdDiagram` renderings. Its metadata definitions provide presentation information consumed by
the local renderer:

- `FpNodePresentation`: node role, tooltip, and explicit lane/member ordering.
- `FpViewPresentation`: short diagram name and layout direction.

These are project-specific metadata/renderings; the model elements and `view` / `expose` / `render`
structure use the supported SysML v2 textual subset.

## Example

```sysml
package Example {
    private import FpDiagram::*;

    action def Map {
        in  value : "F a";
        out _     : "F b";
    }

    action def MapFlow {
        #FpNodePresentation {
            role = "hof";
            tooltip = "The function argument";
            laneId = "plain";
            laneLabel = "Plain values & functions";
            laneOrder = "0";
            laneMemberOrder = "0";
        }
        item f : "a ⟶ b";

        #FpNodePresentation {
            role = "function";
            laneId = "monad";
            laneLabel = "Functor";
            laneOrder = "1";
            laneMemberOrder = "0";
        }
        action map : Map;
        flow from f to map;
    }

    #FpViewPresentation { name = "map"; direction = "LR"; }
    view diagram : FpActivityView {
        doc /* fmap applies a plain function inside the functor. */
        expose MapFlow;
        render fpActivityDiagram;
    }
}
```

Each source has one `view`. Its `expose` target selects the action or part definition to render.
`FpActivityView` and `FpIbdView` select the activity and IBD renderers respectively. The view's
documentation supplies the SVG title; node tooltips and visual roles come from `FpNodePresentation`.

## Practical constraints

- Quote math-heavy type expressions, such as `"F(a ⟶ b)"`.
- Metadata field values are strings or identifiers; lane order values are numeric strings.
- Lane and lane-member ordering must be explicit to keep the motivation diagrams aligned.
- The parser does not resolve imports or type-check against the SysML standard library.
- Extend [`sysml.langium`](sysml.langium) when adding syntax, then regenerate and run
  `make -C .tools test-update` followed by `make -C .tools test`.
