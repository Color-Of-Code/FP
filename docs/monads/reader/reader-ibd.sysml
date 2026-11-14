// SysML v2 — Reader monad IBD: the Reader that bind returns
// (>>=) :: Reader r a ⟶ (a ⟶ Reader r b) ⟶ Reader r b      m >>= f = join (fmap f m)
//
// Generic shape: see docs/19-monad/monad-ibd.sysml. A Reader is a function r ⟶ b, so the
// «block» frame is the Reader that bind returns: its boundary ports are its call interface —
// the environment r in, the result b out. The two things bind was applied to, ma and f, are
// fixed (captured) inside. Here fmap and join are fused into what Reader actually does:
//   • the SAME r is handed to the first computation and to the one f builds from its result
//   • r is read-only: it is shared, never consumed or modified

package ReaderSignature {
    private import FpDiagram::*;

    part def bound {
        #FpNodePresentation { tooltip = "r — the read-only environment, supplied each time the Reader is run"; }
        port in  r      : "r";
        #FpNodePresentation { tooltip = "result : b — the result of running the composed Reader with r"; }
        port out result : "b";

        #FpNodePresentation { role = "hof"; tooltip = "ma : Reader r a — a computation waiting for env r; fixed when bind was applied"; }
        part ma : "Reader r a — captured";
        #FpNodePresentation { role = "hof"; tooltip = "f : a ⟶ Reader r b — user code; given a, produces a new computation waiting for r; fixed when bind was applied"; }
        part f : "a ⟶ Reader r b — captured";

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

        connection connect ma         to run_ma.m : "captured";
        connection connect r          to run_ma.r : "env r";
        connection connect run_ma._   to call.a : "result";
        connection connect f          to call.f : "captured";
        connection connect call._     to run_next.m : "next Reader";
        connection connect r          to run_next.r : "same r";
        connection connect run_next._ to result;
    }

    #FpViewPresentation { name = "bind"; }
    view diagram : FpIbdView {
        doc /*bind :: Reader r a ⟶ (a ⟶ Reader r b) ⟶ Reader r b — inside bind: the same environment r is supplied to both computations — also called: flatMap, >>=*/
        expose bound;
        render fpIbdDiagram;
    }
}
