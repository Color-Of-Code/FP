// SysML v2 — State monad IBD: the State that bind returns
// (>>=) :: State s a ⟶ (a ⟶ State s b) ⟶ State s b      m >>= f = join (fmap f m)
//
// Generic shape: see docs/19-monad/monad-ibd.sysml. A State is a function s ⟶ (b, s), so the
// «block» frame is the State that bind returns: its boundary ports are its call interface —
// the state s in, the result b and the final state s'' out. The two things bind was applied
// to, ma and f, are fixed (captured) inside. Here fmap and join are fused into what State
// actually does:
//   • the first computation consumes s and returns a plus a NEW state s'
//   • the computation f builds runs with s' — not with the original s
// Unlike Reader, the state is modified: each step sees what the previous one left.

package StateSignature {
    private import FpDiagram::*;

    part def bound {
        #FpNodePresentation { tooltip = "s — the state, supplied each time the State is run"; }
        port in  s     : "s";
        #FpNodePresentation { tooltip = "b — the result of running the composed computation"; }
        port out b     : "b";
        #FpNodePresentation { tooltip = "s'' — the final state, after both steps have run"; }
        port out s_out : "s''";

        #FpNodePresentation { role = "hof"; tooltip = "ma : State s a — a computation: given state s returns (a, s'); fixed when bind was applied"; }
        part ma : "State s a — captured";
        #FpNodePresentation { role = "hof"; tooltip = "f : a ⟶ State s b — user code; given result a, produces a new state computation; fixed when bind was applied"; }
        part f : "a ⟶ State s b — captured";

        #FpNodePresentation { role = "function"; tooltip = "Run the first computation: ma s = (a, s')."; }
        part run_ma : "ma s" {
            port in  m  : "State s a";
            port in  s  : "s";
            port out a  : "a";
            port out s1 : "s'";
        }
        #FpNodePresentation { role = "function"; tooltip = "Apply f to the result: yields the next State computation, not yet run."; }
        part call : "f a" {
            port in  f : "a ⟶ State s b";
            port in  a : "a";
            port out _ : "State s b";
        }
        #FpNodePresentation { role = "function"; tooltip = "The State-specific join: run the computation f built with the state s' that the first step left behind — (f a) s' = (b, s'')."; }
        part run_next : "(f a) s'" {
            port in  m  : "State s b";
            port in  s  : "s'";
            port out b  : "b";
            port out s2 : "s''";
        }

        connection connect ma          to run_ma.m : "captured";
        connection connect s           to run_ma.s : "state";
        connection connect run_ma.a    to call.a : "result";
        connection connect f           to call.f : "captured";
        connection connect call._      to run_next.m : "next State";
        connection connect run_ma.s1   to run_next.s : "state threaded";
        connection connect run_next.b  to b;
        connection connect run_next.s2 to s_out;
    }

    #FpViewPresentation { name = "bind"; }
    view diagram : FpIbdView {
        doc /*bind :: State s a ⟶ (a ⟶ State s b) ⟶ State s b — inside bind: the state s' left by the first step is threaded into the second — also called: flatMap, >>=*/
        expose bound;
        render fpIbdDiagram;
    }
}
