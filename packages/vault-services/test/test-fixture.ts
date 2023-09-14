import {providers} from "ethers";
import {SafeAccountConfig} from "@safe-global/protocol-kit";
import {MySigner} from "../src/my-signer";
import {SafeVersion} from "@safe-global/safe-core-sdk-types";
import {SAFE_V130} from "../src/utils/network-config";

export const OWNER_PUBLIC_KEY_LOCAL: string = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266";
export const ALLOWANCE_MODULE_ADDRESS_LOCAL = "0xE46FE78DBfCa5E835667Ba9dCd3F3315E7623F8a";
export const SAFE_VERSION: SafeVersion = SAFE_V130;

export class TestSigners {
    private _ceoSigner: MySigner;
    private _ctoSigner: MySigner;
    private _cfoSigner: MySigner;
    private _investorSigner: MySigner;

    constructor(provider: providers.JsonRpcProvider) {
        this._ceoSigner = new MySigner(0, provider);
        this._cfoSigner = new MySigner(1, provider);
        this._ctoSigner = new MySigner(2, provider);
        this._investorSigner = new MySigner(3, provider);
    }


    get ceoSigner(): MySigner {
        return this._ceoSigner;
    }

    get ctoSigner(): MySigner {
        return this._ctoSigner;
    }

    get cfoSigner(): MySigner {
        return this._cfoSigner;
    }

    get investorSigner(): MySigner {
        return this._investorSigner;
    }

    async createSafeAccountConfig(threshold: number) {
        const ceoAddress = await this._ceoSigner.getAddress()
        const cfoAddress = await this._cfoSigner.getAddress();
        const ctoAddress = await this._ctoSigner.getAddress();
        const invAddress = await this._investorSigner.getAddress();

        const safeAccountConfig: SafeAccountConfig = {
            owners: [ceoAddress, cfoAddress, ctoAddress, invAddress],
            threshold: threshold,
            // ... (optional params)
        }

        return safeAccountConfig;
    }
}