# anon-aadhaar-noir
Anon-Aadhaar protocol implementation in Noir

At this point, the following modules work: 

1. SHA256 Hash
2. RSA Signature Verification
3. Computing the nullifier using the Poseidon Hash function
4. Converting the IST timestamp to UTC UNIX timestamp
5. Conditional Disclosure of Secrets
6. SignalHash constraints for frontrunning atttacks

To run the signature circuit:

1. cd signature_gen
2. cargo check
3. cargo test

And in each of the folders of hash_and_sign, poseidon, nullifier, timestamp, cds, signal:

1. cd folder_name
2. nargo check
3. nargo test
