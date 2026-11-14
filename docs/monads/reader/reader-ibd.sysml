// SysML v2 — Reader monad IBD: inside bind
// (>>=) :: Reader r a ⟶ (a ⟶ Reader r b) ⟶ Reader r b      m >>= f = join (fmap f m)
//
// Generic shape: see docs/19-monad/monad-ibd.sysml. The call interface is the same for every
// monad — ma and f in, mb out. A Reader is a function r ⟶ a, so inside the block we see the
// body of the Reader that bind returns: env is its parameter, supplied only when the result
// is run. Here fmap and join are fused into what Reader actually does:
//   • the SAME r is handed to the first computation and to the one f builds from its result
//   • r is read-only: it is shared, never consumed or modified

package ReaderSignature {
    private import FpDiagram::*;

    part def bind {
        #FpNodePresentation { tooltip = "Reader r a — a computation waiting for env r; when run with r it produces a"; }
        port in  ma : "Reader r a";
        #FpNodePresentation { tooltip = "f : a ⟶ Reader r b — user code; given a, produces a new computation waiting for r"; }
        port in  f  : "a ⟶ Reader r b";
        #FpNodePresentation { tooltip = "Reader r b — the composed computation; a function still waiting for r"; }
        port out mb : "Reader r b";

        #FpNodePresentation { role = "value"; tooltip = "The environment: the parameter of the returned Reader. It is supplied when the Reader is run, not when bind is called. Read-only."; }
        part env : "r — supplied when run";

        #FpNodePresentation { role = "function"; tooltip = "Run the first computation with the environment: ma r."; }
        part run_ma : "ma r" {
            port in  m : "Reader r a";
            port in  r : "r";
            port out _ : "a";
        }
        #FpNodePresentation { role = "function"; tooltip = "Apply f to the result: yields the next Reader, not yet run."; }
        part call : "f a" {
            port in  f : "a ⟶ Reader r b";
            port in  a : "a";
            port out _ : "Reader r b";
        }
        #FpNodePresentation { role = "function"; tooltip = "The Reader-specific join: run the Reader that f built with the SAME environment r — (f a) r."; }
        part run_next : "(f a) r" {
            port in  m : "Reader r b";
            port in  r : "r";
            port out _ : "b";
        }
        #FpNodePresentation { role = "function"; tooltip = "Abstract over r again: the whole body becomes the Reader r b that bind returns."; }
        part wrap : "λr → b" {
            port in  b : "b";
            port out _ : "Reader r b";
        }

        connection connect ma         to run_ma.m : "wrapped";
        connection connect env        to run_ma.r : "env r";
        connection connect run_ma._   to call.a : "result";
        connection connect f          to call.f : "user code";
        connection connect call._     to run_next.m : "next Reader";
        connection connect env        to run_next.r : "same r";
        connection connect run_next._ to wrap.b : "result";
        connection connect wrap._     to mb;
    }

    #FpViewPresentation { name = "bind"; }
    view diagram : FpIbdView {
        doc /*bind :: Reader r a ⟶ (a ⟶ Reader r b) ⟶ Reader r b — inside bind: the same environment r is supplied to both computations — also called: flatMap, >>=*/
        expose bind;
        render fpIbdDiagram;
    }
}
