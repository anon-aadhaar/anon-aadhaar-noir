use crate::helpers::QRData;

pub fn cds_circuit(
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
