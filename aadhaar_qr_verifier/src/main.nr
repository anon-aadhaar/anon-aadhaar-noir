mod tests;
mod signature_verifier;
use signature_verifier::verify_signature;
pub mod helpers;

use helpers::{
    nullifier::nullifier_circuit, signal::signal_circuit, cds::cds_circuit,
    timestamp::{timestamp_circuit, time_stamp_extractor}, extractor::extractor,
};
use bignum::params::BigNumParams;

global RSA_EXPONENT: u32 = 65537;
global MAX_YEARS: Field = 2050;
global INCLUDE_HOURS: bool = true;
global INCLUDE_MINUTES: bool = true;
global INCLUDE_SECONDS: bool = true;
global PHOTO_END_INDEX: u64 = 1152;
global MAX_DATA_LENGTH: u32 = 512 * 3;
global DELIMITER_INDICES_LENGTH: u32 = 18;
global LIMBS_SIZE: u32 = 18;
global KEY_SIZE = 2048;

type QRData = BoundedVec<u8, MAX_DATA_LENGTH>;
type BigN2048 = BigNumParams<LIMBS_SIZE, KEY_SIZE>;

// todo():
// . remove all hardcoded inputs done
// . selective disclosure
// . Timestamp extraction should be a separate function
// . we only need one msg array
// . Check comparation with Field or u8 for datatype
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
    // let values = extractor(qrDataPadded, qrDataPaddedLength, delimiterIndices);
    // let (year_val, month_val, day_val, hour_val, minute_val, second_val, age, gender_data, pincode_data, state_data) =
    //     time_stamp_extractor(delimiterIndices, msg);
    // println("year_val: ", year_val);
    // Define a valid QRData instance
    // let qrDataExtractor =
    //     QRData { ageAbove18: age, gender: gender_data, pinCode: pincode_data, state: state_data };
    // Expected values match qrDataExtractor values
    // let ageAbove18 = age;
    // let gender = gender_data;
    // let pinCode = pincode_data;
    // let state = state_data;
    // // Call the circuit with valid inputs
    // cds_circuit(
    //     revealAgeAbove18,
    //     revealGender,
    //     revealPinCode,
    //     revealState,
    //     qrDataExtractor,
    //     ageAbove18,
    //     gender,
    //     pinCode,
    //     state,
    // );
    // // Calculate nullifier
    // let expectedNullifier = nullifier_circuit(nullifierSeed, delimiterIndices, msg);
    // assert(expectedNullifier != 0, "Computed Nullifier: {expected_nullifier}");
    // std::print("Computed Nullifier: ");
    // std::println(expectedNullifier);
    // // Calculate the Unix timestamp using the circuit
    // let timestamp = timestamp_circuit(
    //     year_val,
    //     month_val,
    //     day_val,
    //     hour_val,
    //     minute_val,
    //     second_val,
    //     // Set maximum year and inclusion flags
    //     MAX_YEARS, // to change into u32
    //     INCLUDE_HOURS,
    //     INCLUDE_MINUTES,
    //     INCLUDE_SECONDS,
    // );
    // assert(timestamp != 0, "Non-zero timestamp computed: {timestamp}");
    // std::print("Timestamp computed: ");
    // std::println(timestamp);
    // // Define a valid signalHash and its square
    // let signalHashSquare = signalHash * signalHash;
    // signal_circuit(signalHash, signalHashSquare);
}

