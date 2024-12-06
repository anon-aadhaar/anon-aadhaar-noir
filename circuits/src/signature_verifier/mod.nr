use dep::rsa::{rsa::verify_sha256_pkcs1v15, types::RBN2048};
use dep::bignum::{params::BigNumParams, RuntimeBigNum};
use crate::{RSA_EXPONENT, QRData, LIMBS_SIZE};
use std::hash::sha256::sha256_var;

global TWO_POW_120: Field = 1329227995784915872903807060280344576;

/// Compresses public key limbs by combining pairs of elements
/// This is safe because the result is max 240 bits, well within Default backend Field size is 254-bits
/// Each pair is combined as: first + (2^120 * second)
fn compress_pubkey(pub_key: [Field; LIMBS_SIZE]) -> [Field; LIMBS_SIZE / 2] {
    let mut compressed = [0; LIMBS_SIZE / 2];
    for i in 0..(LIMBS_SIZE / 2) {
        let idx = i * 2;
        compressed[i] = pub_key[idx] + (TWO_POW_120 * pub_key[idx + 1]);
    }

    compressed
}

/// Verifies the signature of the QR data
pub fn verify_signature(
    qrDataPadded: QRData,
    qrDataPaddedLength: u32,
    signature_limbs: [Field; LIMBS_SIZE],
    modulus_limbs: [Field; LIMBS_SIZE],
    redc_limbs: [Field; LIMBS_SIZE],
) -> Field {
    let sha = sha256_var(qrDataPadded.storage, qrDataPaddedLength as u64);
    let has_multiplicative_inverse = false;
    let params: BigNumParams<18, 2048> =
        BigNumParams::new(has_multiplicative_inverse, modulus_limbs, redc_limbs);

    let signature: RBN2048 = RuntimeBigNum::from_array(params, signature_limbs);

    // posideon hash of compressed public key
    assert(verify_sha256_pkcs1v15(sha, signature, RSA_EXPONENT));

    10

    // let compressed_pub_key = compress_pubkey(modulus_limbs);
    // let pubkey_hash = std::hash::poseidon::bn254::hash_9(compressed_pub_key);

    // pubkey_hash
}
