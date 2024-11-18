pub mod helpers;

mod tests;
mod signature_verifier;
use signature_verifier::verify_signature;
use helpers::{nullifier::nullifier_circuit, signal::signal_circuit, extractor::extractor};

global RSA_EXPONENT: u32 = 65537;
global MAX_YEARS: Field = 2032;
global INCLUDE_HOURS: bool = true;
global INCLUDE_MINUTES: bool = false;
global INCLUDE_SECONDS: bool = false;
global MAX_DATA_LENGTH: u32 = 512 * 3;
global DELIMITER_INDICES_LENGTH: u32 = 18;
global LIMBS_SIZE: u32 = 18;
global IST_OFFSET: Field = 19800;
global MAX_FIELD_BYTE_SIZE: u32 = 32;
global MAX_BYTES_IN_FIELD: u32 = 31;
global MAX_PHOTO_BYTES: u32 = MAX_BYTES_IN_FIELD * MAX_FIELD_BYTE_SIZE;

type QRData = BoundedVec<u8, MAX_DATA_LENGTH>;

pub struct RevealedData {
    pub age: bool,
    pub gender: u32,
    pub pinCode: u32,
    pub state: Field,
    pub timestamp: Field,
    pub nullifier: Field,
}

pub fn aadhar_qr_verifier(
    qrDataPadded: QRData,
    qrDataPaddedLength: u32,
    delimiterIndices: [u8; DELIMITER_INDICES_LENGTH],
    signature_limbs: [Field; LIMBS_SIZE],
    modulus_limbs: [Field; LIMBS_SIZE],
    redc_limbs: [Field; LIMBS_SIZE],
    revealAgeAbove18: bool,
    revealGender: bool,
    revealPinCode: bool,
    revealState: bool,
    nullifierSeed: Field,
    signalHash: Field,
) -> RevealedData {
    // Signature verification
    verify_signature(
        qrDataPadded,
        qrDataPaddedLength,
        signature_limbs,
        modulus_limbs,
        redc_limbs,
    );
    let (age, gender, pincode, state, timestamp, photo) =
        extractor(qrDataPadded, qrDataPaddedLength, delimiterIndices);

    let ageAbove18 = age > 18;
    let outputAge = if revealAgeAbove18 { ageAbove18 } else { false };
    let outputGender = if revealGender { gender } else { 0 };
    let outputPinCode = if revealPinCode { pincode } else { 0 };
    let outputState = if revealState { state } else { 0 };

    let nullifier = nullifier_circuit(nullifierSeed, photo);

    let signalHashSq = signalHash * signalHash;
    signal_circuit(signalHash, signalHashSq);

    RevealedData {
        age: outputAge,
        gender: outputGender,
        pinCode: outputPinCode,
        state: outputState,
        timestamp: timestamp,
        nullifier: nullifier,
    }
}

