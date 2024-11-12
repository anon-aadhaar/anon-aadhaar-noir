mod utils;
mod position;
mod tests;
mod nullifier;
mod timestamp;
mod cds;
mod signal;
use dep::bignum::{params::BigNumParams, RuntimeBigNum};

use utils::{QRData, bytes_to_int_chunks};
use nullifier::nullifier_circuit;
use timestamp::timestamp_circuit;
use cds::cds_circuit;
use signal::signal_circuit;

use position::{
    gender_position, reference_id_position, dob_position, pincode_position, state_position,
    photo_position,
};

use dep::rsa::{rsa::verify_sha256_pkcs1v15, types::RBN2048};

// todo():
// 1. type of public_key should be  BNInst2048
// 2. signature type should be BigNum<18, Params2048>
// 3. remove all hardcoded inputs
// 4. selective disclosure

pub fn extractor_circuit(
    msg: [Field; 1152], // we need to have only one circuit for these
    msg_str: str<2663>,
    // public_key: BNInst2048,
    // signature: BigNum<18, Params2048>,
    signature_limbs: [Field; 18],
    modulus_limbs: [Field; 18],
    redc_limbs: [Field; 18],
    delimiterIndices: [u64; 18],
) {
    let sha256_hash: [u8; 32] = dep::std::hash::sha256(msg_str.as_bytes());

    let has_multiplicative_inverse = false;
    let params: BigNumParams<18, 2048> =
        BigNumParams::new(has_multiplicative_inverse, modulus_limbs, redc_limbs);

    let signature: RBN2048 = RuntimeBigNum::from_array(params, signature_limbs);

    // Verify the RSA signature
    assert(verify_sha256_pkcs1v15(sha256_hash, signature, 65537));

    // Timestamp extraction
    let mut year: [Field; 4] = [0; 4];
    let mut month: [Field; 2] = [0; 2];
    let mut day: [Field; 2] = [0; 2];
    let mut hour: [Field; 2] = [0; 2];
    let year_start_index = delimiterIndices[reference_id_position() - 1] + 5;
    let year_end_index = year_start_index + year.len() as u64;
    let month_start_index = year_end_index;
    let month_end_index = month_start_index + month.len() as u64;
    let day_start_index = month_end_index;
    let day_end_index = day_start_index + day.len() as u64;
    let hour_start_index = day_end_index;
    let hour_end_index = hour_start_index + hour.len() as u64;
    let mut year_val = 0;
    for i in year_start_index..year_end_index {
        year[i - year_start_index] = msg[i] - 48;
        year_val = 10 * year_val + (year[i - year_start_index]);
    }
    let mut month_val = 0;
    for i in month_start_index..month_end_index {
        month[i - month_start_index] = msg[i] - 48;
        month_val = month_val * 10 + month[i - month_start_index];
    }
    let mut day_val = 0;
    for i in day_start_index..day_end_index {
        day[i - day_start_index] = msg[i] - 48;
        day_val = day_val * 10 + day[i - day_start_index];
    }
    let mut hour_val = 0;
    for i in hour_start_index..hour_end_index {
        hour[i - hour_start_index] = msg[i] - 48;
        hour_val = 10 * hour_val + hour[i - hour_start_index];
    }
    let mut minute_val = 0;
    let mut second_val = 0;
    // Date of birth extraction
    let mut birth_year_vec: [Field; 4] = [0; 4];
    let mut birth_month_vec: [Field; 2] = [0; 2];
    let mut birth_date_vec: [Field; 2] = [0; 2];
    let mut age = 0;
    let birthday_start_index = delimiterIndices[dob_position() - 1] + 1;
    let birthday_end_index = delimiterIndices[dob_position()];
    let birth_date_start_index = birthday_start_index;
    let birth_date_end_index = birth_date_start_index + 1;
    let birth_month_start_index = birth_date_end_index + 2;
    let birth_month_end_index = birth_month_start_index + 1;
    let birth_year_start_index = birth_month_end_index + 2;
    let birth_year_end_index = birth_year_start_index + 3;
    for i in birthday_start_index..birthday_end_index {
        if i >= birth_date_start_index & i <= birth_date_end_index {
            birth_date_vec[i - birth_date_start_index] = msg[i] - 48;
        } else if i >= birth_month_start_index & i <= birth_month_end_index {
            birth_month_vec[i - birth_month_start_index] = msg[i] - 48;
        } else if i >= birth_year_start_index & i <= birth_year_end_index {
            birth_year_vec[i - birth_year_start_index] = msg[i] - 48;
        }
    }
    let birth_date_data = birth_date_vec[0] * 10 + birth_date_vec[1];
    let birth_month_data = birth_month_vec[0] * 10 + birth_month_vec[1];
    let birth_year_data = birth_year_vec[0] * 1000
        + birth_year_vec[1] * 100
        + birth_year_vec[2] * 10
        + birth_year_vec[3];
    // Calculate the Age
    let age_by_year = year_val - birth_year_data - 1;
    let mut age = age_by_year;
    if birth_month_data as u64 > month_val as u64 {
        age += 1;
    } else if birth_month_data as u64 == month_val as u64 {
        if birth_date_data as u64 > day_val as u64 {
            age += 1;
        }
    }
    // Calculate the Gender
    let gender_index = delimiterIndices[gender_position() - 1] + 1;
    let gender_data = msg[gender_index] - 65;
    // Calculate the Pincode of the Address
    let pincode_start_index = delimiterIndices[pincode_position() - 1] + 1;
    let pincode_end_index = delimiterIndices[pincode_position()];
    let mut pincode_vec: [Field; 6] = [0; 6];
    for i in pincode_start_index..pincode_end_index {
        pincode_vec[i - pincode_start_index] = msg[i] - 48;
    }
    let mut pincode_data = 0;
    for i in pincode_vec {
        pincode_data = pincode_data * 10 + i;
    }
    // Calculate the State of the Address
    let state_start_index = delimiterIndices[state_position() - 1] + 1;
    let state_end_index = delimiterIndices[state_position()];
    let mut state_vec: [Field; 5] = [0; 5];
    let mut state_data = 0;
    for i in state_start_index..state_end_index {
        state_vec[i - state_start_index] = msg[i] - 65;
        state_data = state_data * 10 + state_vec[i - state_start_index];
    }
    // Define a valid QRData instance
    let qrDataExtractor =
        QRData { ageAbove18: age, gender: gender_data, pinCode: pincode_data, state: state_data };
    // Test with reveal signals set to 1 (reveal the data)
    let revealAgeAbove18 = 1;
    let revealGender = 1;
    let revealPinCode = 1;
    let revealState = 1;
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
    let nullifierSeed: Field = 12345678; // Example seed
    let mut photo_vec: [Field; 967] = [0; 967];
    let photo_start_index = delimiterIndices[photo_position() - 1] + 1;
    let photo_end_index = 1152;
    for i in photo_start_index..photo_end_index {
        photo_vec[i - photo_start_index] = msg[i];
    }
    let photo_bytes_packed = bytes_to_int_chunks(photo_vec);
    let expectedNullifier = nullifier_circuit(nullifierSeed, photo_bytes_packed);
    assert(expectedNullifier != 0, "Computed Nullifier: {expected_nullifier}");
    std::print("Computed Nullifier: ");
    std::println(expectedNullifier);
    // Set maximum year and inclusion flags
    let maxYears = 2050;
    let includeHours = true;
    let includeMinutes = true;
    let includeSeconds = true;
    // Calculate the Unix timestamp using the circuit
    let timestamp = timestamp_circuit(
        year_val,
        month_val,
        day_val,
        hour_val,
        minute_val,
        second_val,
        maxYears,
        includeHours,
        includeMinutes,
        includeSeconds,
    );
    assert(timestamp != 0, "Non-zero timestamp computed: {timestamp}");
    std::print("Timestamp computed: ");
    std::println(timestamp);
    // Define a valid signalHash and its square
    let signalHash = 5;
    let signalHashSquare = 25;
    signal_circuit(signalHash, signalHashSquare);
}

