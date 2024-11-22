use crate::{
    helpers::{
        bytes_array_to_int, DOB_POS, GENDER_POS, PHOTO_POS, PINCODE_POS, STATE_POS, AadharData,
        Date,
    }, DELIMITER_INDICES_LENGTH, INCLUDE_HOURS, INCLUDE_MINUTES, INCLUDE_SECONDS, IST_OFFSET,
    MAX_DATA_LENGTH, MAX_FIELD_BYTE_SIZE, MAX_PHOTO_BYTES, MAX_YEARS, QRData,
};

use nodash::pack_bytes;

pub fn extractor(
    qrDataPadded: QRData,
    qrDataPaddedLength: u32,
    delimiterIndices: [u8; DELIMITER_INDICES_LENGTH],
) -> AadharData {
    let qr_data_arr = qrDataPadded.storage();
    let mut n255_filter: [u32; MAX_DATA_LENGTH + 1] = [0; MAX_DATA_LENGTH + 1];
    let mut nDelimitedData: [u32; MAX_DATA_LENGTH] = [0; MAX_DATA_LENGTH];

    for i in 0..qr_data_arr.len() {
        let is_255 = qr_data_arr[i] == 255;
        let is_less_than_12 = (i as u8) < (delimiterIndices[PHOTO_POS - 1] + 1) as u8;
        let is_255_and_index_before_photo = if is_255 & is_less_than_12 { 1 } else { 0 };

        assert(
            is_255_and_index_before_photo * (is_255_and_index_before_photo - 1) == 0,
            "is_255 && index before photo should be boolean value",
        );

        n255_filter[i + 1] = (is_255_and_index_before_photo as u32) * 255 + n255_filter[i];

        nDelimitedData[i] =
            (is_255_and_index_before_photo as u32) * n255_filter[i] + (qr_data_arr[i] as u32);
    }

    let date = date_extractor(nDelimitedData);

    let timestamp = timestamp_extractor(
        date.year as Field,
        date.month as Field,
        date.day as Field,
        date.hour as Field,
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
        delimiterIndices[(PHOTO_POS - 1) as u64] as u64,
        (qrDataPaddedLength - 1) as u64,
    );

    AadharData { age, gender, pincode, state, timestamp, photo }
}

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

fn timestamp_extractor(
    year: Field,
    month: Field,
    day: Field,
    hour: Field,
    minute: Field,
    second: Field,
    maxYears: Field,
    includeHours: bool,
    includeMinutes: bool,
    includeSeconds: bool,
) -> Field {
    // Validate inputs
    assert(year as u32 >= 1970 & year as u32 <= maxYears as u32);
    assert(month as u32 >= 1 & month as u32 <= 12);
    assert(day as u32 >= 1 & day as u32 <= 31);
    assert(hour as u32 >= 0 & hour as u32 <= 23);
    assert(minute as u32 >= 0 & minute as u32 <= 59);
    assert(second as u32 >= 0 & second as u32 <= 59);

    let DAYS_PER_MONTH: [u64; 12] = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
    let SECONDS_PER_DAY: u64 = 86400;
    let SECONDS_PER_HOUR: u64 = 3600;

    let year_i64 = year as u64;
    let mut total_days = (year_i64 - 1970) * 365 + (day as u64) - 1;

    if month as i64 > 1 {
        total_days += DAYS_PER_MONTH[(month as i64 - 1)];
    }

    // Calculate leap years
    let mut leap_days = 0;
    if year_i64 > 1972 {
        leap_days = ((year_i64 - 1972 - 1) / 4) + 1;
        if (year_i64 >= 1972) & ((year_i64 - 1972) % 4 == 0) & (month as i64 > 2) {
            leap_days += 1;
        }
    }
    total_days += leap_days;

    let mut timestamp = total_days * SECONDS_PER_DAY;
    if includeHours {
        timestamp += (hour as u64) * SECONDS_PER_HOUR;
    }
    if includeMinutes {
        timestamp += (minute as u64) * 60;
    }
    if includeSeconds {
        timestamp += second as u64;
    }

    (timestamp as Field - IST_OFFSET)
}

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

    assert(age_data[0] == (DOB_POS as u32) * 255);
    assert(age_data[11] == ((DOB_POS + 1) as u32) * 255);

    // gender_data[1] -> represent gender
    assert(gender_data[0] == (GENDER_POS as u32) * 255);
    assert(gender_data[2] == ((GENDER_POS + 1) as u32) * 255);

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

fn photo_extractor(
    nDelimitedData: [u32; MAX_DATA_LENGTH],
    start_index: u64,
    end_index: u64,
) -> [Field; 33] {
    let mut state_data_array: [u8; MAX_PHOTO_BYTES] = [0; MAX_PHOTO_BYTES];

    assert(nDelimitedData[start_index] == (PHOTO_POS * 255) as u32);
    assert(end_index - start_index <= MAX_PHOTO_BYTES as u64);

    for i in 0..MAX_PHOTO_BYTES {
        if (start_index + i as u64 + 1) < end_index {
            state_data_array[i] = nDelimitedData[(start_index + i as u64 + 1)] as u8;
        }
    }

    let state_packed_bytes = pack_bytes(state_data_array);
    // todo we don;t need last byte. we can return [field;32] but we need copy entire array.
    // array.remove method?
    state_packed_bytes
}
