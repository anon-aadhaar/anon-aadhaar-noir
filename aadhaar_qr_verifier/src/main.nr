mod tests;
mod signature_verifier;
use signature_verifier::verify_signature;
pub mod helpers;

use helpers::{nullifier::nullifier_circuit, signal::signal_circuit, extractor::extractor};
use bignum::params::BigNumParams;

global RSA_EXPONENT: u32 = 65537;
global MAX_YEARS: Field = 2032;
global INCLUDE_HOURS: bool = true;
global INCLUDE_MINUTES: bool = true;
global INCLUDE_SECONDS: bool = true;
global PHOTO_END_INDEX: u64 = 1152;
global MAX_DATA_LENGTH: u32 = 512 * 3;
global DELIMITER_INDICES_LENGTH: u32 = 18;
global LIMBS_SIZE: u32 = 18;
global KEY_SIZE = 2048;
global PHOTO_SIZE: u32 = 32;
global IST_OFFSET: u32 = 19800;
global MAX_FIELD_BYTE_SIZE: u32 = 32;
global MAX_BYTES_IN_FIELD: u32 = 31;

type QRData = BoundedVec<u8, MAX_DATA_LENGTH>;

// todo():
// (done) remove all hardcoded inputs done
// (done)selective disclosure
// (done) Timestamp extraction should be a separate function
// (done) we only need one msg array
// (done) Check comparation with Field or u8 for datatype

// . refactor things and write test for in test dir
// . use generic and give max length most of things
// . type of public_key should be BNInst2048
// - signature type should be BigNum<18, Params2048>
// - all reveal tag should bool instead of field

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
) {
    // Signature verification
    verify_signature(
        qrDataPadded,
        qrDataPaddedLength,
        signature_limbs,
        modulus_limbs,
        redc_limbs,
    );
    let (age, gender, pincode, state, timestamp) = extractor(qrDataPadded, delimiterIndices);

    let ageAbove18 = age > 18;

    // TODO RETURN THIS VALUE INSTEAD OF PRINTING
    // todo return age
    if revealAgeAbove18 {
        println(ageAbove18);
    }
    if (revealGender) {
        println(gender);
    }
    if (revealPinCode) {
        println(pincode);
    }
    if (revealState) {
        println(state);
    }
}

