fn main(signalHash: Field, signalHashSquare: Field) {
    // Enforce the constraint that signalHashSquare is the square of signalHash
    assert(signalHashSquare == signalHash * signalHash);
}

#[test]
fn test_valid_hash_square() {
    // Define a valid signalHash and its square
    let signalHash = 5;
    let signalHashSquare = 25;

    // Call the circuit with valid inputs
    main(signalHash, signalHashSquare);
}
