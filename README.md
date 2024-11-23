# Anon-Aadhaar Protocol Implementation in Noir

This project implements the Anon-Aadhaar protocol using Noir.

## Modules

- `/circuits`: **Noir Circuits**
- `/scripts`: **scripts for generating testcases**

## Setup

### Prerequisites

Note: Ensure you have Noir version **0.38.0** and barretenberg backend verison **0.61.0**

installed and
. If not, set it specfic version using the following command:

```sh
noirup -v 0.36.0
bbup -v 0.61.0
```

### Build circuits:

```sh
cd circuits
nargo compile
```

### Testing

To run the tests:

```sh
nargo test --show-output
```

### Testing with Real Data

To run the tests with read data:

1. Setup scripts:

   ```sh
   cd scripts
   yarn install
   ```

2. Configure environment:

   - Create `.env` in `scripts` directory with:

   ```sh
   export REAL_DATA=true
   export QR_DATA= <aadhar data (bigint)>
   ```

3. Generate test inputs:

   ```sh
   yarn gen-test-inputs
   ```

   This creates test inputs in `circuits/testcases/test.toml`

4. Execute tests with real data:
   ```sh
   nargo execute -p test.toml
   ```

## Benchmarks

Will be updating soon.
Benchmarks via the Barretenberg Backend on M1 Macbook Pro 2020:

| Part of the Circuit | Number of Gates | Proving Time | Verification Time |
| ------------------- | --------------- | ------------ | ----------------- |
| Aadhaar QR Verifier | 237811          |              |                   |
