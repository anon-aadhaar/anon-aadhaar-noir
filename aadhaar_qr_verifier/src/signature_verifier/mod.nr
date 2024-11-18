use dep::rsa::{rsa::verify_sha256_pkcs1v15, types::RBN2048};
use dep::bignum::{params::BigNumParams, RuntimeBigNum};
use crate::{RSA_EXPONENT, QRData, LIMBS_SIZE};
use std::hash::sha256::sha256_var;

pub fn verify_signature<>(
    qrDataPadded: QRData,
    qrDataPaddedLength: u32,
    signature_limbs: [Field; LIMBS_SIZE],
    modulus_limbs: [Field; LIMBS_SIZE],
    redc_limbs: [Field; LIMBS_SIZE],
) {
    let sha = sha256_var(qrDataPadded.storage, qrDataPaddedLength as u64);
    let has_multiplicative_inverse = false;
    let params: BigNumParams<18, 2048> =
        BigNumParams::new(has_multiplicative_inverse, modulus_limbs, redc_limbs);
    let signature: RBN2048 = RuntimeBigNum::from_array(params, signature_limbs);

    // verify rsa signature
    assert(verify_sha256_pkcs1v15(sha, signature, RSA_EXPONENT));
}
