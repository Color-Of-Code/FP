// SysML v2 — tagless final IBD: what a program does with its algebra
// program :: (Console F, Monad F) ⟹ F ()
//   program = readLine >>= \name -> writeLine name
//
// Reading guide:
//   • a tagless-final program is a function of its instance: the «block» frame is the
//     program, its boundary ports are the dictionary inst going in and the effect F ()
//     coming out — choosing an interpreter means choosing what to pass here
//   • every operation the program uses is reached THROUGH inst — readLine, writeLine
//     and even >>= are inst's fields; the program has no other access to the world
//   • swap inst (real IO, a pure test stub) and everything inside changes meaning while
//     the program itself stays byte-for-byte the same
//   • an operation not offered by inst simply cannot be written — the capability
//     list is the type

package TaglessFinalSignature {
    private import FpDiagram::*;

    part def program {
        #FpNodePresentation { tooltip = "inst : Console F, Monad F — the interpreter: a dictionary of the operations the program may use. Chosen by the caller."; }
        port in  inst : "Algebra F";
        #FpNodePresentation { tooltip = "F () — the program as an effect in whatever F the instance defines: IO in production, State Log in tests"; }
        port out r    : "F ()";

        #FpNodePresentation { role = "function"; tooltip = "inst.readLine :: F String — an operation of the algebra, not a concrete read."; }
        part read : "readLine" {
            port in  i : "Algebra F";
            port out _ : "F String";
        }
        #FpNodePresentation { role = "function"; tooltip = "λname → inst.writeLine name :: String ⟶ F () — the next step, built from another operation of the same algebra."; }
        part write : "λname → writeLine name" {
            port in  i : "Algebra F";
            port out _ : "String ⟶ F ()";
        }
        #FpNodePresentation { role = "function"; tooltip = "inst's Monad F: sequencing is also supplied by the instance. IO runs the effects in order; a pure instance threads a log."; }
        part bind_f : ">>= of F" {
            port in  i : "Algebra F";
            port in  m : "F String";
            port in  k : "String ⟶ F ()";
            port out _ : "F ()";
        }

        connection connect inst       to read.i : "readLine from inst";
        connection connect inst       to write.i : "writeLine from inst";
        connection connect inst       to bind_f.i : "sequencing from inst";
        connection connect read._     to bind_f.m : "F String";
        connection connect write._    to bind_f.k : "continuation";
        connection connect bind_f._   to r;
    }

    #FpViewPresentation { name = "program"; }
    view diagram : FpIbdView {
        doc /*program :: Algebra F ⟹ F () — inside the program: every operation, even sequencing, is reached through the instance inst*/
        expose program;
        render fpIbdDiagram;
    }
}
