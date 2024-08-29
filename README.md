# anon-aadhaar-noir
Anon-Aadhaar protocol implementation in Noir

At this point, the following modules work: 

1. SHA256 Hash
2. RSA Signature Verification
3. Conditional Disclosure of Secrets
4. Computing the nullifier using the Poseidon Hash function
5. Converting the IST timestamp to UTC UNIX timestamp
6. SignalHash constraints for frontrunning atttacks

To run the entire circuit:

1. cd aadhaar_qr_verifier
2. nargo check --overwrite
3. nargo test

To run the RSA-SHA256 circuit:

1. cd rsa-sha256
2. noirup -v 0.32.0
3. nargo check --overwrite
4. nargo test

And in each of the folders of hash_and_sign, poseidon, nullifier, timestamp, cds, signal:

1. cd folder_name
2. nargo check --overwrite
3. nargo test
