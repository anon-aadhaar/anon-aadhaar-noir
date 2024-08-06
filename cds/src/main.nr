// Define a struct to hold the extracted QR data
struct QRData {
    ageAbove18: Field,
    gender: Field,
    pinCode: Field,
    state: Field,
}

fn main(
    revealAgeAbove18: Field,
    revealGender: Field,
    revealPinCode: Field,
    revealState: Field,
    qrDataExtractor: QRData,
    ageAbove18: Field,
    gender: Field,
    pinCode: Field,
    state: Field,
) {
    // Enforce binary constraints on reveal signals
    assert(revealAgeAbove18 * (revealAgeAbove18 - 1) == 0);
    assert(revealGender * (revealGender - 1) == 0);
    assert(revealPinCode * (revealPinCode - 1) == 0);
    assert(revealState * (revealState - 1) == 0);

    // Assign extracted values conditionally based on the reveal signals
    assert(ageAbove18 == revealAgeAbove18 * qrDataExtractor.ageAbove18);
    assert(gender == revealGender * qrDataExtractor.gender);
    assert(pinCode == revealPinCode * qrDataExtractor.pinCode);
    assert(state == revealState * qrDataExtractor.state);
}

#[test]
fn test_valid_reveal_constraints() {
    // Define a valid QRData instance
    let qrDataExtractor = QRData {
        ageAbove18: 1,
        gender: 1,
        pinCode: 12345,
        state: 42,
    };

    // Test with reveal signals set to 1 (reveal the data)
    let revealAgeAbove18 = 1;
    let revealGender = 1;
    let revealPinCode = 1;
    let revealState = 1;

    // Expected values match qrDataExtractor values
    let ageAbove18 = 1;
    let gender = 1;
    let pinCode = 12345;
    let state = 42;

    // Call the circuit with valid inputs
    main(
        revealAgeAbove18,
        revealGender,
        revealPinCode,
        revealState,
        qrDataExtractor,
        ageAbove18,
        gender,
        pinCode,
        state,
    );
}
