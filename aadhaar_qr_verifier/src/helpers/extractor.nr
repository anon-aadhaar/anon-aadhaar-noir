use crate::{DELIMITER_INDICES_LENGTH, MAX_DATA_LENGTH};

// todo it should return correct year ,month, day, hour,
pub fn extractor(
    qrDataPadded: BoundedVec<u8, MAX_DATA_LENGTH>,
    qrDataPaddedLength: u32,
    delimiterIndices: [u8; DELIMITER_INDICES_LENGTH],
) -> [u8; 4] {
    [1, 1, 1, 1]
}
