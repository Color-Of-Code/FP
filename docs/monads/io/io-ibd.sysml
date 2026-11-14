// SysML v2 — IO monad IBD: inside bind
// (>>=) :: IO a ⟶ (a ⟶ IO b) ⟶ IO b      m >>= f = join (fmap f m)
//
// Generic shape: see docs/19-monad/monad-ibd.sysml. The call interface is the same for every
// monad — ma and f in, mb out. An IO value is a recipe, so inside the block we see the script
// of the recipe bind returns, as the runtime executes it. Here fmap and join are fused into
// what IO actually does — a strict sequence of two executions:
//   • first the effects of ma happen, producing a
//   • only then is f a evaluated, and the recipe it returns is executed too
// Nothing runs while the recipe is merely being composed.

package IOSignature {
    private import FpDiagram::*;

    part def bind {
        #FpNodePresentation { tooltip = "IO a — a description of a side-effectful computation. Nothing runs yet."; }
        port in  ma : "IO a";
        #FpNodePresentation { tooltip = "f : a ⟶ IO b — user code; given the result of running ma, returns the next IO action"; }
        port in  f  : "a ⟶ IO b";
        #FpNodePresentation { tooltip = "IO b — the composed recipe. Effects of ma happen before effects of f(a)."; }
        port out mb : "IO b";

        #FpNodePresentation { role = "function"; tooltip = "Execute the first recipe: its side effects happen now, producing a."; }
        part run_ma : "execute ma" {
            port in  _ : "IO a";
            port out _ : "a";
        }
        #FpNodePresentation { role = "function"; tooltip = "Apply f to the result: yields the next recipe, not yet executed. The choice of the next effect can depend on a."; }
        part call : "f a" {
            port in  f : "a ⟶ IO b";
            port in  a : "a";
            port out _ : "IO b";
        }
        #FpNodePresentation { role = "function"; tooltip = "The IO-specific join: execute the recipe f built. Its effects happen strictly after those of ma — order of effects = order of binds."; }
        part run_next : "execute (f a)" {
            port in  _ : "IO b";
            port out _ : "b";
        }
        #FpNodePresentation { role = "function"; tooltip = "Package the whole script as one recipe, to be executed by the runtime."; }
        part wrap : "recipe" {
            port in  _ : "b";
            port out _ : "IO b";
        }

        connection connect ma         to run_ma._ : "wrapped";
        connection connect run_ma._   to call.a : "effects done, result a";
        connection connect f          to call.f : "user code";
        connection connect call._     to run_next._ : "next recipe";
        connection connect run_next._ to wrap._ : "result";
        connection connect wrap._     to mb;
    }

    #FpViewPresentation { name = "bind"; }
    view diagram : FpIbdView {
        doc /*bind :: IO a ⟶ (a ⟶ IO b) ⟶ IO b — inside bind: execute ma, feed its result to f, then execute the recipe f returns — also called: .then (Promises), >>=*/
        expose bind;
        render fpIbdDiagram;
    }
}
