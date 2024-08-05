use dep::std;

fn main(preimage: [u8; 3], hash : pub [u8; 32]) {
    let h = std::hash::sha256(preimage);
    assert(h==hash);
}

#[test]
fn test_main() {
    let preimage = [4, 2, 0];
    let hash = [24, 67, 78, 52, 81, 51, 75, 186,
                149, 43, 134, 15, 156, 169, 194, 248,
                218, 249, 157, 110, 163, 98, 225, 167, 
                127, 9, 3, 173, 165, 249, 3, 51
    ];
    main(preimage, hash);
}
