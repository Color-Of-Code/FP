// SysML v2 — CPS IBD: the function that toCps returns
// toCps :: (a ⟶ b) ⟶ (a ⟶ (b ⟶ r) ⟶ r)      toCps f x k = k (f x)
//
// Reading guide:
//   • the «block» frame is the CPS function; its boundary ports are its call interface:
//     the argument x and the continuation k in, the answer r out
//   • f is fixed (captured) when toCps builds the function — it lives inside
//   • f x still computes b, but b does not RETURN to the caller: it is handed to k
//   • the answer r is whatever k produces — the rest of the program takes over from here

package CpsSignature {
    private import FpDiagram::*;

    part def cps_f {
        #FpNodePresentation { tooltip = "x : a — the argument, supplied on every call"; }
        port in  x      : "a";
        #FpNodePresentation { tooltip = "k : b ⟶ r — the continuation: what to do with the result, i.e. the rest of the computation. Supplied on every call."; }
        port in  k      : "b ⟶ r";
        #FpNodePresentation { tooltip = "result : r — the answer, produced by k. The function never returns b."; }
        port out result : "r";

        #FpNodePresentation { role = "hof"; tooltip = "f : a ⟶ b — an ordinary function that returns its result; fixed when toCps was applied"; }
        part f : "a ⟶ b — captured";

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

        connection connect f       to run_f.f : "captured";
        connection connect x       to run_f.a : "argument";
        connection connect run_f._ to call_k.b : "b (not returned)";
        connection connect k       to call_k.k : "continuation";
        connection connect call_k._ to result;
    }

    #FpViewPresentation { name = "toCps"; }
    view diagram : FpIbdView {
        doc /*toCps :: (a ⟶ b) ⟶ (a ⟶ (b ⟶ r) ⟶ r) — inside toCps: f computes b, but b is handed to the continuation k instead of being returned*/
        expose cps_f;
        render fpIbdDiagram;
    }
}
