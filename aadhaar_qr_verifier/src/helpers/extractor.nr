use crate::{DELIMITER_INDICES_LENGTH, MAX_DATA_LENGTH, QRData};
use crate::helpers::{photo_position, bytes_array_to_int, dob_position};
use crate::MAX_YEARS;
use crate::INCLUDE_HOURS;
use crate::INCLUDE_MINUTES;
use crate::INCLUDE_SECONDS;
use crate::IST_OFFSET;
use super::gender_position;
use super::pincode_position;
use super::state_position;
use super::max_field_byte_size;

pub fn extractor(
    qrDataPadded: QRData,
    delimiterIndices: [u8; DELIMITER_INDICES_LENGTH],
) -> (u32, u32, u32, u32, Field) {
    let qr_data_arr = qrDataPadded.storage();
    let mut n255_filter: [u32; MAX_DATA_LENGTH + 1] = [0; MAX_DATA_LENGTH + 1];
    let mut nDelimitedData: [u32; MAX_DATA_LENGTH] = [0; MAX_DATA_LENGTH];

    for i in 0..qr_data_arr.len() {
        // current value is delimiter (255)
        let is_255 = if qr_data_arr[i] == 255 { true } else { false };

        // current index is before photo position
        let is_less_than_12 = if (i as u8) < (delimiterIndices[photo_position() - 1] + 1) as u8 {
            true
        } else {
            false
        };

        let is_255_and_index_before_photo = (is_255 & is_less_than_12) as u32;

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

    (age, gender, pincode, state, timestamp)
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

// Define the main function for converting date and time to a Unix timestamp
pub fn timestamp_extractor(
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
    // Ensure the input values are within valid ranges by casting to integers
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

    // Days till the start of each month in a non-leap year
    let daysTillPreviousMonth: [i64; 12] = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];

    // Calculate the number of years and leap years since 1970
    let yearsSinceEpoch: i64 = (year as i64) - 1970;
    let leapYears: i64 = (yearsSinceEpoch + 1) / 4;

    // Calculate days passed in the current year
    let mut daysPassedInCurrentYear: i64 = (day as i64) - 1;
    for i in 0..12 {
        if (month as i32) - 1 > i as i32 {
            daysPassedInCurrentYear += daysTillPreviousMonth[i];
        }
    }

    // Add an extra day if it's a leap year and the date is after February
    if (month as i32) > 2 & ((year as i32 - 1972) % 4 == 0) {
        daysPassedInCurrentYear += 1;
    }

    // Calculate total days passed since Unix epoch
    let totalDaysPassed: i64 = yearsSinceEpoch * 365 + leapYears + daysPassedInCurrentYear;

    // Calculate the Unix timestamp
    let mut timestamp: i64 = totalDaysPassed * 86400;

    // Add hours, minutes, and seconds if included
    if includeHours {
        timestamp += (hour as i64) * 3600;
    }
    if includeMinutes {
        timestamp += (minute as i64) * 60;
    }
    if includeSeconds {
        timestamp += (second as i64);
    }

    // Output the final timestamp with ist offset
    (timestamp as Field - IST_OFFSET as Field)
}

pub fn age_and_gender_extractor(
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

pub fn state_extractor(
    nDelimitedData: [u32; MAX_DATA_LENGTH],
    delimiterIndices: [u8; DELIMITER_INDICES_LENGTH],
    extractPosition: u64,
) -> u32 {
    let startDelimiterIndex = delimiterIndices[(extractPosition - 1)] as u32;
    let endDelimiterIndex = delimiterIndices[extractPosition] as u32;

    let mut state_vector: Vec<u32> = Vec::new();
    let max_byte_size = max_field_byte_size();
    let bytelenth = (max_byte_size + 1) as u32;

    for i in startDelimiterIndex..endDelimiterIndex {
        state_vector.push(nDelimitedData[i]);
    }
    for _ in endDelimiterIndex..endDelimiterIndex + bytelenth {
        state_vector.push(0);
    }

    assert(state_vector.get(0) == (extractPosition * 255) as u32);

    let end_delimitor_val = nDelimitedData[endDelimiterIndex];
    assert(end_delimitor_val == ((extractPosition + 1) * 255) as u32);

    // TODO (VIKAS): Fix the pack bytes fn
    // let ans = pack_bytes(array, 32);
    // println(ans);
    0
}
