// SysML v2 — IO monad IBD: what happens inside bind
// (>>=) :: IO a ⟶ (a ⟶ IO b) ⟶ IO b      m >>= f = join (fmap f m)
//
// IO a is a description (recipe) of a side-effectful computation. Nothing runs
// while this diagram is evaluated — bind only builds a bigger recipe:
//   • fmap builds a recipe whose result is itself a recipe: IO (IO b)
//   • join builds a recipe that runs the outer recipe, then the recipe it produced

package IOSignature {
    private import FpDiagram::*;

    part def bind {
        #FpNodePresentation { tooltip = "IO a — a description of a side-effectful computation. Nothing runs yet."; }
        port in  ma : "IO a";
        #FpNodePresentation { tooltip = "f : a ⟶ IO b — user code; given the result of running ma, returns the next IO action"; }
        port in  f  : "a ⟶ IO b";
        #FpNodePresentation { tooltip = "IO b — the composed recipe. Effects of ma happen before effects of f(a). Never IO (IO b)."; }
        port out mb : "IO b";

        #FpNodePresentation { role = "function"; tooltip = "fmap f :: IO a ⟶ IO (IO b)\nA recipe that runs ma and returns f a — a new recipe — without running it."; }
        part fmap : "IO a ⟶ IO (IO b)" {
            port in  f : "a ⟶ IO b";
            port in  _ : "IO a";
            port out _ : "IO (IO b)";
        }
        #FpNodePresentation { role = "function"; tooltip = "join :: IO (IO b) ⟶ IO b — the IO-specific part\nA recipe that, when run by the runtime:\n1. runs the outer recipe to obtain the inner recipe\n2. runs the inner recipe\nOrder of effects = order of binds."; }
        part join : "IO (IO b) ⟶ IO b" {
            port in  _ : "IO (IO b)";
            port out _ : "IO b";
        }

        connection connect ma      to fmap._ : "wrapped";
        connection connect f       to fmap.f : "user code";
        connection connect fmap._  to join._ : "nested (internal only)";
        connection connect join._  to mb;
    }

    #FpViewPresentation { name = "bind"; }
    view diagram : FpIbdView {
        doc /*bind :: IO a ⟶ (a ⟶ IO b) ⟶ IO b — inside bind: fmap f, then join runs outer then inner recipe — also called: .then (Promises), >>=*/
        expose bind;
        render fpIbdDiagram;
    }
}
