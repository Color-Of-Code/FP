// SysML v2 — Writer monad IBD: inside bind
// (>>=) :: (a, w1) ⟶ (a ⟶ (b, w2)) ⟶ (b, w1<>w2)      m >>= f = join (fmap f m)
//
// Generic shape: see docs/19-monad/monad-ibd.sysml. Here fmap and join are fused into
// what Writer actually does — the value and the log travel on separate wires:
//   • the value a goes into f; the first log w1 bypasses f entirely
//   • f returns a new result b with its own log w2
//   • the logs are merged with the monoid append w1 <> w2 (first step first)

package WriterSignature {
    private import FpDiagram::*;

    part def bind {
        #FpNodePresentation { tooltip = "(a, w1) — a result value a paired with a log fragment w1"; }
        port in  ma : "(a, w1)";
        #FpNodePresentation { tooltip = "f : a ⟶ (b, w2) — user code; given a, produces result b alongside a new log fragment w2"; }
        port in  f  : "a ⟶ (b, w2)";
        #FpNodePresentation { tooltip = "(b, w1<>w2) — result b with the complete log"; }
        port out mb : "(b, w1<>w2)";

        #FpNodePresentation { role = "function"; tooltip = "Take the pair apart: the value a is for f, the log w1 is set aside."; }
        part split : "(a, w1)" {
            port in  _  : "(a, w1)";
            port out a  : "a";
            port out w1 : "w1";
        }
        #FpNodePresentation { role = "function"; tooltip = "Apply f to the value only — it never sees the earlier log."; }
        part call : "f a" {
            port in  f : "a ⟶ (b, w2)";
            port in  a : "a";
            port out _ : "(b, w2)";
        }
        #FpNodePresentation { role = "function"; tooltip = "The Writer-specific join: keep b, append the logs in execution order — w1 <> w2 (Monoid append, e.g. list concatenation)."; }
        part combine : "(b, w1 <> w2)" {
            port in  w1 : "w1";
            port in  r  : "(b, w2)";
            port out _  : "(b, w1<>w2)";
        }

        connection connect ma       to split._ : "wrapped";
        connection connect f        to call.f : "user code";
        connection connect split.a  to call.a : "value";
        connection connect split.w1 to combine.w1 : "log bypasses f";
        connection connect call._   to combine.r : "result + new log";
        connection connect combine._ to mb;
    }

    #FpViewPresentation { name = "bind"; }
    view diagram : FpIbdView {
        doc /*bind :: (a, w1) ⟶ (a ⟶ (b, w2)) ⟶ (b, w1<>w2) — inside bind: the value goes to f; the two logs bypass it and are appended — also called: flatMap, >>=*/
        expose bind;
        render fpIbdDiagram;
    }
}
