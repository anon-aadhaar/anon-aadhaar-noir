# anon-aadhaar-noir

Anon-Aadhaar protocol implementation in Noir

The following modules work:

1. SHA256 Hash
2. RSA Signature Verification
3. Conditional Disclosure of Secrets
4. Computing the nullifier using the Poseidon Hash function
5. Converting the IST timestamp to UTC UNIX timestamp
6. SignalHash constraints for frontrunning atttacks

To run the entire circuit:

1. cd aadhaar_qr_verifier
2. nargo check --overwrite
3. nargo test --show-output

To run the RSA-SHA256 circuit:

1. cd rsa-sha256
2. noirup -v 0.32.0
3. nargo check --overwrite
4. nargo test

And in each of the folders nullifier, timestamp, cds, signal:

1. cd folder_name
2. nargo check --overwrite
3. nargo test

Benchmarks via the Barretenberg Backend:

| Part of the Circuit | Proving Time | Verification Time |
| ------------------- | ------------ | ----------------- |
| RSA-SHA256          | 0.502s       | 0.064             |

The Verification Cost of the Solidity Verifier of the entire Aadhaar_QR_Verifier circuit:

Total Gas Cost: 2904342 gas  
Transaction Cost: 2525514 gas  
Execution Cost: 2251848 gas
