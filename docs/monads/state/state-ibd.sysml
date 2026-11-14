// SysML v2 — State monad IBD: inside bind
// (>>=) :: State s a ⟶ (a ⟶ State s b) ⟶ State s b      m >>= f = join (fmap f m)
//
// Generic shape: see docs/19-monad/monad-ibd.sysml. The call interface is the same for every
// monad — ma and f in, mb out. A State is a function s ⟶ (a, s), so inside the block we see
// the body of the State that bind returns: s0 is its parameter, supplied only when the
// result is run. Here fmap and join are fused into what State actually does:
//   • the first computation consumes s0 and returns a plus a NEW state s'
//   • the computation f builds runs with s' — not with the original s0
// Unlike Reader, the state is modified: each step sees what the previous one left.

package StateSignature {
    private import FpDiagram::*;

    part def bind {
        #FpNodePresentation { tooltip = "State s a — a computation: given state s returns (a, s')"; }
        port in  ma : "State s a";
        #FpNodePresentation { tooltip = "f : a ⟶ State s b — user code; given result a, produces a new state computation"; }
        port in  f  : "a ⟶ State s b";
        #FpNodePresentation { tooltip = "State s b — the composed computation; a function still waiting for a state"; }
        port out mb : "State s b";

        #FpNodePresentation { role = "value"; tooltip = "The initial state: the parameter of the returned State. It is supplied when the State is run, not when bind is called."; }
        part s0 : "s — supplied when run";

        #FpNodePresentation { role = "function"; tooltip = "Run the first computation: ma s0 = (a, s')."; }
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
        #FpNodePresentation { role = "function"; tooltip = "Abstract over s again: the result and the final state s'' become the State s b that bind returns."; }
        part wrap : "λs → (b, s'')" {
            port in  b  : "b";
            port in  s2 : "s''";
            port out _  : "State s b";
        }

        connection connect ma          to run_ma.m : "wrapped";
        connection connect s0          to run_ma.s : "initial state";
        connection connect run_ma.a    to call.a : "result";
        connection connect f           to call.f : "user code";
        connection connect call._      to run_next.m : "next State";
        connection connect run_ma.s1   to run_next.s : "state threaded";
        connection connect run_next.b  to wrap.b : "result";
        connection connect run_next.s2 to wrap.s2 : "final state";
        connection connect wrap._      to mb;
    }

    #FpViewPresentation { name = "bind"; }
    view diagram : FpIbdView {
        doc /*bind :: State s a ⟶ (a ⟶ State s b) ⟶ State s b — inside bind: the state s' left by the first step is threaded into the second — also called: flatMap, >>=*/
        expose bind;
        render fpIbdDiagram;
    }
}
