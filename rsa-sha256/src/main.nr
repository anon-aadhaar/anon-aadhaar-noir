use dep::bignum::BigNum;
use dep::bignum::runtime_bignum::BigNumInstance;
use dep::bignum::runtime_bignum::BigNumTrait;
use dep::bignum::runtime_bignum::BigNumInstanceTrait;
use dep::bignum::runtime_bignum::BigNumParamsTrait;
use dep::bignum::utils::u60_representation::U60Repr;
use dep::bignum::utils::arrayX::ArrayX;
use dep::bignum::fields::Params2048;
use dep::bignum::fields::Params1024;

struct RSA<BN, BNInstance, let NumBytes: u32>{}

/**
 * @brief Compare a recovered byte hash from an RSA signature to the original message hash
 * @details Taken from https://github.com/richardliang/noir-rsa
 **/
fn compare_signature_sha256<let N: u32>(padded_sha256_hash: [u8; N], msg_hash: [u8; 32]) -> bool {
    // Get length of sig (e.g. 1048 = 128 bytes, 2048 = 256 bytes)
    // NOTE: Assume MAX_BYTES < 2^32 bit number. MAX_BYTES of 259 > 2^8 bits so need to cast it to u32

    for i in 0..32 {
        // Padded hash is reversed
        assert(padded_sha256_hash[31 - i] == msg_hash[i]);
    }

    let hash_prefix: [u8; 19] = [32, 4, 0, 5, 1, 2, 4, 3, 101, 1, 72, 134, 96, 9, 6, 13, 48, 49, 48];

    for i in 32..51 {
        assert(hash_prefix[i - 32] == padded_sha256_hash[i]);
    }

    assert(padded_sha256_hash[51] == 0);

    // Sub 32 bytes for hash, 19 bytes for prefix, 1 byte for 0, 1 byte for 1, 1 byte for 0
    let ps_len = N - 54;
    for i in 52..N {
        if i as u32 < 52 + ps_len as u32 {
            // PS padding which depends on RSA modulus / sig length. 1024 bits = 128 bytes = 128 - 54 = 74 bytes of 0xFF padding
            assert(padded_sha256_hash[i] == 255);
        } else if i as u32 == 52 + ps_len as u32 {
            // Pad 0x01
            assert(padded_sha256_hash[i] == 1);
        } else if i as u32 == 53 + ps_len as u32 {
            // 0x00
            assert(padded_sha256_hash[i] == 0);
        } else {
            // Padded with 0 until MAX_BYTES
            assert(padded_sha256_hash[i] == 0);
        }
    }

    true
}
impl<BN, BNInstance, let NumBytes: u32> RSA<BN, BNInstance, NumBytes>  where BN: BigNumTrait, BNInstance: BigNumInstanceTrait<BN> {
    /**
 * @brief Verify an RSA signature generated via the pkcs1v15 signature scheme.
 * @details The fourth function parameter is required to define the value of `NBytes`
 *          when converting a BigNum into a byte array, the number of bytes is required and currently cannot be inferred.
 *          Once numeric generics can be derived by applying operations to other numeric generics the need for this will go away.
 *
 * @note We assume the public key exponent `e` is 65537 
 * Rough cost: 2,048 bit RSA: 26,888 gates per verification
 *             1,024 bit RSA: 11,983 gates per verification
 * A circuit that verifies 1 signature (and does nothing else) will cost ~32k due to initialization costs of lookup tables
 **/
    pub fn verify_sha256_pkcs1v15(_: Self, public_key: BNInstance, msg_hash: [u8; 32], sig: BN) -> bool {
        // e = 65537 = 1 0000 0000 0000 0001
        let mut exponentiated = public_key.mul(sig, sig);
        exponentiated = public_key.mul(exponentiated, exponentiated);
        exponentiated = public_key.mul(exponentiated, exponentiated);
        exponentiated = public_key.mul(exponentiated, exponentiated);
        exponentiated = public_key.mul(exponentiated, exponentiated);
        exponentiated = public_key.mul(exponentiated, exponentiated);
        exponentiated = public_key.mul(exponentiated, exponentiated);
        exponentiated = public_key.mul(exponentiated, exponentiated);
        exponentiated = public_key.mul(exponentiated, exponentiated);
        exponentiated = public_key.mul(exponentiated, exponentiated);
        exponentiated = public_key.mul(exponentiated, exponentiated);
        exponentiated = public_key.mul(exponentiated, exponentiated);
        exponentiated = public_key.mul(exponentiated, exponentiated);
        exponentiated = public_key.mul(exponentiated, exponentiated);
        exponentiated = public_key.mul(exponentiated, exponentiated);
        exponentiated = public_key.mul(exponentiated, exponentiated);
        exponentiated = public_key.mul(exponentiated, sig);

        let mut padded_sha256_hash_bytes: [u8; NumBytes] = exponentiated.to_le_bytes();
        compare_signature_sha256(padded_sha256_hash_bytes, msg_hash)
    }
}

type BN1024 = BigNum<9, Params1024>;
type BN2048 = BigNum<18, Params2048>;
type BNInst1024 = BigNumInstance<9, Params1024>;
type BNInst2048 = BigNumInstance<18, Params2048>;

type RSA1024 = RSA<BN1024, BNInst1024, 128>;
type RSA2048 = RSA<BN2048, BNInst2048, 256>;

#[test]
fn main() {
    let msg = "86502555125550545755504850524855495649505253535551565525583117109105116327511710997114255484945484945495756522557725567477932731151041199711432671049711010025569971151163268101108104105255255664551494432511141003270108111111114255255494948485349255751141051151041109732789710397114255681011081041052558297100104101121328310412197109328097114107326912011610111011510511111025571971101001041053278971039711425575114105115104110973278971039711425549505152255255792558104700000600006000000000000600006000000000037117117112558201220011544002559203566111241102341102341101881030103010222695769576951007237237269792107921079972551000340167114101971161011003298121583274745048484832118101114115105111110325246492551440100000223601255820122001154400255147255145040019523554111283816625514504011922496512816124552551450402192249650141752551450403195238413123741312328156122712814782441981019012874255145040419230103229702406415157125620616124255145040519212040719614122412816128161441021555255145040619523515131232297202363512311932211332201731232912419051158143042342161451518991822104590170523420915813108213781581372551450407192565615132112351641551612402402324214825514504081924932292075911316324138108156262551450409193241271352061221514418425252119237209173196150111252462381101672459724144213187170613323211993120413517139512748209141130143722001502338524155128173216495221613911091225301092041881461572141887328915710124618722311750628165205126255145040101602848341261891711052172551450401116058483513717561198184255145040121992002226271240248106128111222255137221220278232331161141251131002261624169361222317120240512716810925015559720612710818105216235321599317520823870166172160625851254855972461381291371633165205221869216310870251681309616213106787125489108233225399763171342950300130281545162151178125652354716224112152119138321210284248361936319310125421380591067974170227110220420118260114606519514823214530462321928159291531012061622810880229255145040131282551450401412825514504015195224188135193127151341961586220424517353224681022151735824481111311102451661561662157615815610170148182601151731761611516918711138226185241978834140218123203881128814374108171063769149691512153720920112581117124102108252251261410422935222191991801102447126104141232237115473117619011124311618532185121575919765612339818172235821461502413018617216115514817121223717012385177761322303811451254363723620221444820319115422219136728214717263173241376214114123112371062196840622925514504016128255145040171282552172358915253593318619356291171431162102652241501755729179517317321212324425047255139965434219243921002401822552116791244127531651802231312211847453233255238301665157243";
    let sha256_hash: [u8; 32] = dep::std::hash::sha256(msg.as_bytes());
    let public_key: BNInst2048 = BigNumInstance::new(
        [
            0x2b465b3fb690242e1235c670dcfb25, 0x640a8933d7daca84a4acef904154b4, 0x62edbfe63e266a5bd8b709e161c8ad, 0x67e5fca1ee7abce8c55e2af10e3c88, 0x47e169541fbcad1db03cdb3bb6ddb4, 0xb2010527709bcd13954404f47e63cb, 0xa2da280f98291de2db2eea3b1198db, 0x5379b351c475a2661b5e51073e019c, 0x204877f0a93bb50a5ae94d2e9cd04a, 0xf23d4f80b1b93f53797ccfa2121e84, 0x5ad9d98cb0522f897f860a3394fec4, 0x9d88eb75090dbe760e4113ef7c3a4e, 0xaf43185f371a0a183ab9bdfc89f17a, 0x06f9b343e7418c83f7f2adafa38505, 0xbb8c5f0c296bcf5ba749849934cb20, 0x0ecf5c0b916c7a8cc5f7b3ff3e6802, 0xe32855596c16ad483cfd9b3aba4ca9, 0xc8
        ],
        [
            0xad8f34cd345f30e43b259e4158a38e, 0xa9c21f74a74d8ab1f31e4ed62d77c2, 0x04a05a51292d7851b2e36ebf922f6c, 0xc265cfa84ce216bf0285d1a89de99c, 0xd1b75109da5df9816fd8de2dfbccf0, 0xf97a0cfb88274326c09889d02cf16e, 0x9c4e239737d77db8987c3b61d835b4, 0xcd1b11e167a6f227a434d62ed67287, 0x0155d9e93e23c5a91615d3d6eae3a8, 0xc89834a0ba80e9cb7d2786ea17aebb, 0xfaaafdb930a62b8d148b94ac6c5979, 0xc31dc3dd65743e58a8ba68277e259b, 0x83fb6ef8085ad3111835fd7ff0662d, 0xe7a5d6ea604882d638bc750fbb3a51, 0xd3ede61d4490ec2e19ffe560a1c0ee, 0xd8e7de313b7c321381b0cead3bfe57, 0x3b8c8aa30c5a7108f1d689de8eb837, 0x0146
        ]
    );
    let signature: BigNum<18, Params2048> = BigNum::from_array([0x05c6e0981bbc3b57a3a1fced4d17da, 0xc91eb859d2829b53dc4e498135fff1, 0xcfaaf3614931fbd153dd4178298723, 0xeba33602ef3c36f2ac342a07998b04, 0x0b8f5b19985490400aaf8f203906dd, 0x34ec83e9af254e6bd9024b1275e44b, 0xcb0710065948ca3e4fc5ca85676716, 0xbc2d33b6c7a4f9cf6c46d5e63b6a40, 0x3a543d690a16366a4a46b88720c944, 0x42479ca91ed769178b4a5a17c139b7, 0x71f39517ba6eaa91d035d690265e8d, 0x235ff0a16468b337f77a9b75d1bb9a, 0x03b4a44f63c446c9d945b8f7febf52, 0xc24de09a1a355f94fe46346b7830bb, 0xcc49c7bbe646f78197054169e0787e, 0xad7871ecf1ab2d0956aa7cdfd7dd1b, 0x46b8fd8d0c49f1ce2eef7e4f817ff3, 0xbd]);
    let rsa: RSA2048 = RSA {};
    assert(rsa.verify_sha256_pkcs1v15(public_key, sha256_hash, signature));
}
