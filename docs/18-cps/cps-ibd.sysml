// SysML v2 — CPS IBD: what a CPS conversion does to a function
// toCps :: (a ⟶ b) ⟶ (a ⟶ (b ⟶ r) ⟶ r)      toCps f x k = k (f x)
//
// Reading guide:
//   • the «block» frame is toCps; its boundary ports are its whole call interface:
//     the direct-style function f in, the CPS function out
//   • toCps applies nothing itself — inside the block we see the body of the returned
//     function, as it runs when called: x and k are its two parameters, supplied only then
//   • f x still computes b, but b does not RETURN to the caller: it is handed to k
//   • the answer r is whatever k produces — the rest of the program takes over from here

package CpsSignature {
    private import FpDiagram::*;

    part def toCps {
        #FpNodePresentation { tooltip = "f : a ⟶ b — an ordinary function that returns its result"; }
        port in  f  : "a ⟶ b";
        #FpNodePresentation { tooltip = "a ⟶ (b ⟶ r) ⟶ r — the same computation, but it takes a continuation and calls it instead of returning"; }
        port out fk : "a ⟶ (b ⟶ r) ⟶ r";

        #FpNodePresentation { role = "value"; tooltip = "The argument: supplied when the CPS function is called."; }
        part x : "a — supplied when called";
        #FpNodePresentation { role = "value"; tooltip = "The continuation: what to do with the result — the rest of the computation. Supplied when the CPS function is called."; }
        part k : "b ⟶ r — supplied when called";

        #FpNodePresentation { role = "function"; tooltip = "The original computation: f x produces b."; }
        part run_f : "f x" {
            port in  f : "a ⟶ b";
            port in  a : "a";
            port out _ : "b";
        }
        #FpNodePresentation { role = "function"; tooltip = "Instead of returning b to a caller, hand it to the continuation: k b. Control passes forward; nothing returns here."; }
        part call_k : "k b" {
            port in  k : "b ⟶ r";
            port in  b : "b";
            port out _ : "r";
        }
        #FpNodePresentation { role = "function"; tooltip = "Abstract over x and k again: the whole body becomes the CPS function that toCps returns."; }
        part wrap : "λx k → r" {
            port in  _ : "r";
            port out _ : "a ⟶ (b ⟶ r) ⟶ r";
        }

        connection connect f       to run_f.f : "direct function";
        connection connect x       to run_f.a : "argument";
        connection connect run_f._ to call_k.b : "b (not returned)";
        connection connect k       to call_k.k : "continuation";
        connection connect call_k._ to wrap._ : "answer";
        connection connect wrap._  to fk;
    }

    #FpViewPresentation { name = "toCps"; }
    view diagram : FpIbdView {
        doc /*toCps :: (a ⟶ b) ⟶ (a ⟶ (b ⟶ r) ⟶ r) — inside toCps: f computes b, but b is handed to the continuation k instead of being returned*/
        expose toCps;
        render fpIbdDiagram;
    }
}
