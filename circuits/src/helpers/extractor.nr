use crate::{
    DELIMITER_INDICES_LENGTH,
    helpers::{
        AadharData, bytes_array_to_int, Date, DOB_POS, GENDER_POS, PHOTO_POS, PINCODE_POS,
        STATE_POS,
    },
    INCLUDE_HOURS,
    INCLUDE_MINUTES,
    INCLUDE_SECONDS,
    IST_OFFSET,
    MAX_DATA_LENGTH,
    MAX_FIELD_BYTE_SIZE,
    MAX_PHOTO_BYTES,
    MAX_YEARS,
    QRData,
};

use nodash::pack_bytes;

/// Aadhaar QRDataExtractor
/// Extracts the name, date, gender, photo from the Aadhaar QR data
fn extractor(
    qrDataPadded: QRData,
    qrDataPaddedLength: u32,
    delimiterIndices: [u8; DELIMITER_INDICES_LENGTH],
) -> AadharData {
    let qr_data_arr = qrDataPadded.storage();
    let mut n255_filter: [u32; MAX_DATA_LENGTH + 1] = [0; MAX_DATA_LENGTH + 1];
    let mut nDelimitedData: [u32; MAX_DATA_LENGTH] = [0; MAX_DATA_LENGTH];

    for i in 0..qr_data_arr.len() {
        let is_255 = qr_data_arr[i] == 255;
        let is_less_than_12 = (i as u8) < (delimiterIndices[PHOTO_POS - 1] + 1);
        let is_255_and_index_before_photo = if is_255 & is_less_than_12 { 1 } else { 0 };

        n255_filter[i + 1] = is_255_and_index_before_photo * 255 + n255_filter[i];

        nDelimitedData[i] =
            is_255_and_index_before_photo * n255_filter[i] + (qr_data_arr[i] as u32);
    }

    let date = date_extractor(nDelimitedData);

    let timestamp = timestamp_extractor(
        date.year,
        date.month,
        date.day,
        date.hour,
        0,
        0,
        MAX_YEARS,
        INCLUDE_HOURS,
        INCLUDE_MINUTES,
        INCLUDE_SECONDS,
    );

    assert(timestamp != 0, "timestamp should not be 0");

    let (age, gender) = age_and_gender_extractor(
        nDelimitedData,
        (delimiterIndices[(DOB_POS - 1)]) as u32,
        date.year,
        date.month,
        date.day,
    );

    let pincode = pincode_extractor(nDelimitedData, delimiterIndices[(PINCODE_POS - 1)] as u32);

    let state = state_extractor(nDelimitedData, delimiterIndices, STATE_POS);

    let photo = photo_extractor(
        nDelimitedData,
        delimiterIndices[(PHOTO_POS - 1)] as u32,
        (qrDataPaddedLength - 1),
    );

    AadharData { age, gender, pincode, state, timestamp, photo }
}

/// Date extractor
/// Extract date of birth from the Aadhaar QR data
/// 170 gates
fn date_extractor(nDelimitedData: [u32; MAX_DATA_LENGTH]) -> Date {
    Date {
        year: bytes_array_to_int(
            [nDelimitedData[9], nDelimitedData[10], nDelimitedData[11], nDelimitedData[12]],
            4,
        ),
        month: bytes_array_to_int([nDelimitedData[13], nDelimitedData[14]], 2),
        day: bytes_array_to_int([nDelimitedData[15], nDelimitedData[16]], 2),
        hour: bytes_array_to_int([nDelimitedData[17], nDelimitedData[18]], 2),
    }
}

/// Timestamp extractor
/// Extracts the timestamp when the QR was signed rounded to nearest hour
/// We ignore minutes and seconds to avoid identifying the user based on the precise timestamp
/// 200 gates
fn timestamp_extractor(
    year: u32,
    month: u32,
    day: u32,
    hour: u32,
    minute: u32,
    second: u32,
    maxYears: u32,
    includeHours: bool,
    includeMinutes: bool,
    includeSeconds: bool,
) -> Field {
    // Range checks
    assert(year >= 1970 & year <= maxYears);
    assert(month >= 1 & month <= 12);
    assert(day >= 1 & day <= 31);
    assert(hour >= 0 & hour <= 23);
    assert(minute >= 0 & minute <= 59);
    assert(second >= 0 & second <= 59);

    let DAYS_PER_MONTH: [Field; 12] = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
    let SECONDS_PER_DAY: Field = 86400;
    let SECONDS_PER_HOUR: Field = 3600;

    let mut total_days: Field = (year as Field - 1970) * 365 + (day as Field) - 1;

    if month > 1 {
        total_days += DAYS_PER_MONTH[(month - 1)];
    }

    // Calculate leap years
    let mut leap_days = 0;
    if year > 1972 {
        leap_days = ((year - 1972 - 1) / 4) + 1;
        if (year >= 1972) & ((year - 1972) % 4 == 0) & (month > 2) {
            leap_days += 1;
        }
    }
    total_days += leap_days as Field;

    let mut timestamp = total_days * SECONDS_PER_DAY;
    if includeHours {
        timestamp += (hour as Field) * SECONDS_PER_HOUR;
    }
    if includeMinutes {
        timestamp += (minute as Field) * 60;
    }
    if includeSeconds {
        timestamp += second as Field;
    }

    (timestamp - IST_OFFSET)
}

/// Age and Gender extractor
/// Extracts age and gender from the Aadhaar QR data
//  300 gates
fn age_and_gender_extractor(
    nDelimitedData: [u32; MAX_DATA_LENGTH],
    startDelimiterIndex: u32,
    currentYear: u32,
    currentMonth: u32,
    currentDay: u32,
) -> (u32, u32) {
    let mut age_data = [0; 12];
    let mut gender_data = [0; 12];

    for i in 0..12 {
        age_data[i] = nDelimitedData[(startDelimiterIndex + i)];
        gender_data[i] = nDelimitedData[(startDelimiterIndex + i) + 11];
    }

    assert(age_data[0] == (DOB_POS) * 255);
    assert(age_data[11] == (DOB_POS + 1) * 255);

    // gender_data[1] -> represent gender
    assert(gender_data[0] == GENDER_POS * 255);
    assert(gender_data[2] == (GENDER_POS + 1) * 255);

    let year = bytes_array_to_int([age_data[7], age_data[8], age_data[9], age_data[10]], 4);
    let month = bytes_array_to_int([age_data[4], age_data[5]], 2);
    let day = bytes_array_to_int([age_data[1], age_data[2]], 2);

    let age_by_year = currentYear - year - 1;

    // +1 to age if month is above currentMonth, or if months are same and day is higher;
    // Check if current month is greater than birth month
    let month_gt = if currentMonth > month { 1 } else { 0 };

    // Check if months are equal
    let month_eq = if currentMonth == month { 1 } else { 0 };

    // Check if current day is greater than birth day (adding 1 as per original logic)
    let day_gt = if (currentDay + 1) > day { 1 } else { 0 };

    // Calculate if we should add a year based on the month/day comparison
    let is_higher_day_on_same_month = month_eq * day_gt;

    let age = age_by_year + month_gt + is_higher_day_on_same_month;
    let gender = gender_data[1];

    (age, gender)
}

/// Pincode extractor
/// Extracts the pincode from the Aadhaar QR data
//  70 gates
fn pincode_extractor(nDelimitedData: [u32; MAX_DATA_LENGTH], startDelimiterIndex: u32) -> u32 {
    // pincode data is 8 bytes long
    let mut pincode_data = [0; 8];
    for i in 0..8 {
        pincode_data[i] = nDelimitedData[(startDelimiterIndex + i)];
    }

    assert(pincode_data[0] == (PINCODE_POS * 255) as u32);
    assert(pincode_data[7] == (PINCODE_POS + 1) as u32 * 255);

    let pincode = bytes_array_to_int(
        [
            pincode_data[1],
            pincode_data[2],
            pincode_data[3],
            pincode_data[4],
            pincode_data[5],
            pincode_data[6],
        ],
        6,
    );
    pincode
}

/// State extractor
/// Extracts the state from the Aadhaar QR data
//  400 gates
fn state_extractor(
    nDelimitedData: [u32; MAX_DATA_LENGTH],
    delimiterIndices: [u8; DELIMITER_INDICES_LENGTH],
    extractPosition: u64,
) -> Field {
    let startDelimiterIndex = delimiterIndices[(extractPosition - 1)] as u32;
    let endDelimiterIndex = delimiterIndices[extractPosition] as u32;

    assert(nDelimitedData[startDelimiterIndex] == (extractPosition * 255) as u32);
    assert(endDelimiterIndex - startDelimiterIndex <= MAX_FIELD_BYTE_SIZE as u32);

    let mut state_data_array: [u8; MAX_FIELD_BYTE_SIZE] = [0; MAX_FIELD_BYTE_SIZE];

    for i in 0..MAX_FIELD_BYTE_SIZE {
        if (startDelimiterIndex + i as u32 + 1) < endDelimiterIndex {
            state_data_array[i] = nDelimitedData[startDelimiterIndex + i as u32 + 1] as u8;
        }
    }

    let state_packed_bytes = pack_bytes(state_data_array);
    state_packed_bytes[0]
}

/// Photo extractor
/// Extracts the photo from the Aadhaar QR data
// 11k gates
fn photo_extractor(
    nDelimitedData: [u32; MAX_DATA_LENGTH],
    start_index: u32,
    end_index: u32,
) -> [Field; 33] {
    let mut state_data_array: [u8; MAX_PHOTO_BYTES] = [0; MAX_PHOTO_BYTES];

    assert(nDelimitedData[start_index] == (PHOTO_POS * 255) as u32);
    assert(end_index - start_index <= MAX_PHOTO_BYTES);

    for i in 0..MAX_PHOTO_BYTES {
        let is_within_bounds = (start_index + i + 1) < end_index;
        if is_within_bounds {
            state_data_array[i] = nDelimitedData[(start_index + i + 1)] as u8;
        }
    }

    let state_packed_bytes = pack_bytes(state_data_array);
    // todo we don;t need last byte. we can return [field;32] but we need copy entire array.
    // array.remove method?
    state_packed_bytes
}
