use crate::{
    helpers::{
        bytes_array_to_int, dob_position, gender_position, photo_position, pincode_position,
        state_position,
    }, DELIMITER_INDICES_LENGTH, INCLUDE_HOURS, INCLUDE_MINUTES, INCLUDE_SECONDS, IST_OFFSET,
    MAX_DATA_LENGTH, MAX_FIELD_BYTE_SIZE, MAX_PHOTO_BYTES, MAX_YEARS, QRData,
};
use nodash::pack_bytes;

pub fn extractor(
    qrDataPadded: QRData,
    qrDataPaddedLength: u32,
    delimiterIndices: [u8; DELIMITER_INDICES_LENGTH],
) -> (u32, u32, u32, Field, Field, [Field; 33]) {
    let qr_data_arr = qrDataPadded.storage();
    let mut n255_filter: [u32; MAX_DATA_LENGTH + 1] = [0; MAX_DATA_LENGTH + 1];
    let mut nDelimitedData: [u32; MAX_DATA_LENGTH] = [0; MAX_DATA_LENGTH];

    for i in 0..qr_data_arr.len() {
        let is_255 = qr_data_arr[i] == 255;
        let is_less_than_12 = (i as u8) < (delimiterIndices[photo_position() - 1] + 1) as u8;
        let is_255_and_index_before_photo = if is_255 & is_less_than_12 { 1 } else { 0 };

        assert(
            is_255_and_index_before_photo * (is_255_and_index_before_photo - 1) == 0,
            "is_255 && index before photo should be boolean value",
        );

        n255_filter[i + 1] = (is_255_and_index_before_photo as u32) * 255 + n255_filter[i];

        nDelimitedData[i] =
            (is_255_and_index_before_photo as u32) * n255_filter[i] + (qr_data_arr[i] as u32);
    }

    let (year, month, day, hour) = date_extractor(nDelimitedData);

    let timestamp = timestamp_extractor(
        year as Field,
        month as Field,
        day as Field,
        hour as Field,
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
        (delimiterIndices[(dob_position() - 1)]) as u32,
        year,
        month,
        day,
    );

    let pincode = pincode_extractor(
        nDelimitedData,
        delimiterIndices[(pincode_position() - 1)] as u32,
    );

    let state = state_extractor(nDelimitedData, delimiterIndices, state_position());

    let photo = photo_extractor(
        nDelimitedData,
        delimiterIndices[(photo_position() - 1) as u64] as u64,
        (qrDataPaddedLength - 1) as u64,
    );

    (age, gender, pincode, state, timestamp, photo)
}

pub fn date_extractor(nDelimitedData: [u32; MAX_DATA_LENGTH]) -> (u32, u32, u32, u32) {
    let year = bytes_array_to_int(
        [
            nDelimitedData[9] as u8,
            nDelimitedData[10] as u8,
            nDelimitedData[11] as u8,
            nDelimitedData[12] as u8,
        ],
        4,
    );
    let month = bytes_array_to_int([nDelimitedData[13] as u8, nDelimitedData[14] as u8], 2);
    let day = bytes_array_to_int([nDelimitedData[15] as u8, nDelimitedData[16] as u8], 2);
    let hour = bytes_array_to_int([nDelimitedData[17] as u8, nDelimitedData[18] as u8], 2);

    (year, month, day, hour)
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
    assert(year as u32 >= 1970);
    assert(year as u32 <= maxYears as u32);
    assert(month as u32 >= 1);
    assert(month as u32 <= 12);
    assert(day as u32 >= 1);
    assert(day as u32 <= 31);
    assert(hour as u32 >= 0);
    assert(hour as u32 <= 23);
    assert(minute as u32 >= 0);
    assert(minute as u32 <= 59);
    assert(second as u32 >= 0);
    assert(second as u32 <= 59);

    // Days till the start of each month in a non-leap year (same as Circom)
    let daysTillPreviousMonth: [i64; 12] = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];

    let yearsSinceEpoch: i64 = (year as i64) - 1970;
    let baseDays: i64 = yearsSinceEpoch * 365;

    let mut totalDays: i64 = baseDays + (day as i64) - 1;

    let currentMonth = month as i64;
    if currentMonth > 1 {
        totalDays += daysTillPreviousMonth[(currentMonth - 1)];
    }

    let mut leapDays: i64 = 0;

    if year as i64 > 1972 {
        leapDays += ((year as i64 - 1972 - 1) / 4) + 1;
    }

    let isCurrentYearLeap = (year as i64 >= 1972) & ((year as i64 - 1972) % 4 == 0);
    if isCurrentYearLeap & currentMonth > 2 {
        leapDays += 1;
    }

    totalDays += leapDays;

    let mut timestamp: i64 = totalDays * 86400;

    if includeHours {
        timestamp += (hour as i64) * 3600;
    }
    if includeMinutes {
        timestamp += (minute as i64) * 60;
    }
    if includeSeconds {
        timestamp += second as i64;
    }

    (timestamp as Field - IST_OFFSET) // Output the final timestamp with ist offset
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

    assert(age_data[0] == (dob_position() as u32) * 255);
    assert(age_data[11] == ((dob_position() + 1) as u32) * 255);

    // gender_data[1] -> represent gender
    assert(gender_data[0] == (gender_position() as u32) * 255);
    assert(gender_data[2] == ((gender_position() + 1) as u32) * 255);

    let year = bytes_array_to_int(
        [age_data[7] as u8, age_data[8] as u8, age_data[9] as u8, age_data[10] as u8],
        4,
    );

    let month = bytes_array_to_int([age_data[4] as u8, age_data[5] as u8], 2);

    let day = bytes_array_to_int([age_data[1] as u8, age_data[2] as u8], 2);

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

pub fn pincode_extractor(nDelimitedData: [u32; MAX_DATA_LENGTH], startDelimiterIndex: u32) -> u32 {
    // pincode data is 8 bytes long
    let mut pincode_data = [0; 8];
    for i in 0..8 {
        pincode_data[i] = nDelimitedData[(startDelimiterIndex + i)];
    }

    assert(pincode_data[0] == (pincode_position() * 255) as u32);
    assert(pincode_data[7] == (pincode_position() + 1) as u32 * 255);

    let pincode = bytes_array_to_int(
        [
            pincode_data[1] as u8,
            pincode_data[2] as u8,
            pincode_data[3] as u8,
            pincode_data[4] as u8,
            pincode_data[5] as u8,
            pincode_data[6] as u8,
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

    assert(nDelimitedData[start_index] == (photo_position() * 255) as u32);
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
