fn main(signalHash: Field, signalHashSquare: Field) {
    // Enforce the constraint that signalHashSquare is the square of signalHash
    assert(signalHashSquare == signalHash * signalHash);
}

#[test]
fn test_valid_hash_square() {
    let signalHash = 5;
    let signalHashSquare = 25;

    main(signalHash, signalHashSquare);
}
