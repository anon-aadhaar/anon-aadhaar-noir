export declare function getPublicKeyModulusFromCertificate(certificate: string): Promise<bigint>;
export type GenerateCircuitInputsOptions = {
    useTestingKey: boolean;
    nullifierSeed: number;
    signal: string;
    revealGender: boolean;
    revealAgeAbove18: boolean;
    revealPinCode: boolean;
    revealState: boolean;
};
export declare function generateCircuitInputs(aadhaarQRData: string, options: GenerateCircuitInputsOptions): Promise<{
    qrDataPadded: {
        len: number;
        storage: string[];
    };
    qrDataPaddedLength: string;
    nullifierSeed: string;
    delimiterIndices: string[];
    signature_limbs: string[];
    modulus_limbs: string[];
    redc_limbs: string[];
    revealGender: string;
    revealAgeAbove18: string;
    revealPinCode: string;
    revealState: string;
    signalHash: string;
}>;
export declare function generateProof(qrData: string, options: GenerateCircuitInputsOptions): Promise<{
    proof: Uint8Array;
    publicInputs: string[];
    provingTime: number;
}>;
export declare function verifyProof(proof: any): Promise<boolean>;
