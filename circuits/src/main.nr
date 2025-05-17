pub mod helpers;
mod tests;
mod signature_verifier;
use helpers::{extractor::extractor, nullifier::nullifier_circuit, signal::signal_circuit};
use signature_verifier::verify_signature;

global RSA_EXPONENT: u32 = 65537;
global MAX_YEARS: u32 = 2032;
global INCLUDE_HOURS: bool = true;
global INCLUDE_MINUTES: bool = false;
global INCLUDE_SECONDS: bool = false;
global MAX_DATA_LENGTH: u32 = 1200;
global DELIMITER_INDICES_LENGTH: u32 = 18;
global LIMBS_SIZE: u32 = 18;
global IST_OFFSET: Field = 19800;
global MAX_FIELD_BYTE_SIZE: u32 = 32;
global MAX_BYTES_IN_FIELD: u32 = 31;
global MAX_PHOTO_BYTES: u32 = MAX_BYTES_IN_FIELD * MAX_FIELD_BYTE_SIZE;

type QRData = BoundedVec<u8, MAX_DATA_LENGTH>;

pub struct RevealedData {
    age: bool,
    gender: u32,
    pincode: u32,
    state: Field,
    timestamp: Field,
    nullifier: Field,
    pubkey_hash: Field,
}

// circuit size: 169810
pub fn main(
    qrDataPadded: QRData,
    qrDataPaddedLength: u32,
    delimiterIndices: [u8; DELIMITER_INDICES_LENGTH],
    signature_limbs: [u128; LIMBS_SIZE],
    modulus_limbs: [u128; LIMBS_SIZE],
    redc_limbs: [u128; LIMBS_SIZE],
    revealAgeAbove18: bool,
    revealGender: bool,
    revealPinCode: bool,
    revealState: bool,
    nullifierSeed: Field,
    signalHash: Field,
) -> pub RevealedData {
    // Signature verification and pubkey hash extraction
    // 1,80,860 Gates
    let pubkey_hash = verify_signature(
        qrDataPadded,
        qrDataPaddedLength,
        signature_limbs,
        modulus_limbs,
        redc_limbs,
    );

    // Extracting data from QR code
    // 46829 Gates
    let AadharData = extractor(qrDataPadded, qrDataPaddedLength, delimiterIndices);

    // Selective Disclosure
    let ageAbove18 = AadharData.age > 18;
    let outputAge = if revealAgeAbove18 { ageAbove18 } else { false };
    let outputGender = if revealGender { AadharData.gender } else { 0 };
    let outputPinCode = if revealPinCode { AadharData.pincode } else { 0 };
    let outputState = if revealState { AadharData.state } else { 0 };

    // Nullifier
    let nullifier = nullifier_circuit(nullifierSeed, AadharData.photo);

    // Signal
    let signalHashSq = signalHash * signalHash;
    signal_circuit(signalHash, signalHashSq);

    RevealedData {
        age: outputAge,
        gender: outputGender,
        pincode: outputPinCode,
        state: outputState,
        timestamp: AadharData.timestamp,
        nullifier,
        pubkey_hash,
    }
}

