mod utils;
mod position;
mod tests;
mod nullifier;
mod timestamp;
mod cds;
mod signature_verifier;
mod signal;
use utils::QRData;
use nullifier::nullifier_circuit;
use cds::cds_circuit;
use signal::signal_circuit;
use signature_verifier::verify_signature;
use timestamp::timestamp_circuit;

global RSA_EXPONENT: u32 = 65537;
global MAX_YEARS: Field = 2050;
global INCLUDE_HOURS: bool = true;
global INCLUDE_MINUTES: bool = true;
global INCLUDE_SECONDS: bool = true;
global PHOTO_END_INDEX: u64 = 1152;

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

pub fn extractor_circuit(
    msg: [Field; 1152], // we need to have only one circuit for these
    msg_str: str<2663>,
    signature_limbs: [Field; 18],
    modulus_limbs: [Field; 18],
    redc_limbs: [Field; 18],
    delimiterIndices: [u64; 18],
    revealAgeAbove18: Field,
    revealGender: Field,
    revealPinCode: Field,
    revealState: Field,
    nullifierSeed: Field,
    signalHash: Field,
) {
    // Signature verification
    verify_signature(msg_str, signature_limbs, modulus_limbs, redc_limbs);

    let (year_val, month_val, day_val, hour_val, minute_val, second_val, age, gender_data, pincode_data, state_data) =
        timestamp::time_stamp_extractor(delimiterIndices, msg);

    // Define a valid QRData instance
    let qrDataExtractor =
        QRData { ageAbove18: age, gender: gender_data, pinCode: pincode_data, state: state_data };

    // Expected values match qrDataExtractor values
    let ageAbove18 = age;
    let gender = gender_data;
    let pinCode = pincode_data;
    let state = state_data;

    // Call the circuit with valid inputs
    cds_circuit(
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

    // Calculate nullifier
    let expectedNullifier = nullifier_circuit(nullifierSeed, delimiterIndices, msg);
    assert(expectedNullifier != 0, "Computed Nullifier: {expected_nullifier}");
    std::print("Computed Nullifier: ");
    std::println(expectedNullifier);

    // Calculate the Unix timestamp using the circuit
    let timestamp = timestamp_circuit(
        year_val,
        month_val,
        day_val,
        hour_val,
        minute_val,
        second_val,
        // Set maximum year and inclusion flags
        MAX_YEARS, // to change into u32
        INCLUDE_HOURS,
        INCLUDE_MINUTES,
        INCLUDE_SECONDS,
    );

    assert(timestamp != 0, "Non-zero timestamp computed: {timestamp}");
    std::print("Timestamp computed: ");
    std::println(timestamp);

    // Define a valid signalHash and its square
    let signalHashSquare = signalHash * signalHash;
    signal_circuit(signalHash, signalHashSquare);
}

