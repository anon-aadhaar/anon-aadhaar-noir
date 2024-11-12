pub fn signal_circuit(signalHash: Field, signalHashSquare: Field) {
    // Dummy square to prevent signal tampering (in rare cases where non-constrained inputs are ignored)
    // Enforce the constraint that signalHashSquare is the square of signalHash
    assert(signalHashSquare == signalHash * signalHash);
}
