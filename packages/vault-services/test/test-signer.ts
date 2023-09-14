import {providers} from "ethers";
import {SafeAccountConfig} from "@safe-global/protocol-kit";
import {SafeVersion} from "@safe-global/safe-core-sdk-types";
import {SAFE_V130} from "../src/utils/network-config";

export const OWNER_PUBLIC_KEY_LOCAL: string = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266";
export const SAFE_VERSION: SafeVersion = SAFE_V130;

export class TestSigner {
    private provider: providers.JsonRpcProvider;
    private _delegate: providers.JsonRpcSigner;

    constructor(index: number, provider: providers.JsonRpcProvider) {
        this.provider = provider;
        this._delegate = provider.getSigner(index);
    }

    getAddress(): Promise<string> {
        let address = this._delegate.getAddress();

        return address;
    }


    getDelegate(): providers.JsonRpcSigner {
        return this._delegate;
    }
}

export class TestSigners {
    private _ceoSigner: TestSigner;
    private _ctoSigner: TestSigner;
    private _cfoSigner: TestSigner;
    private _investorSigner: TestSigner;

    constructor(provider: providers.JsonRpcProvider) {
        this._ceoSigner = new TestSigner(0, provider);
        this._cfoSigner = new TestSigner(1, provider);
        this._ctoSigner = new TestSigner(2, provider);
        this._investorSigner = new TestSigner(3, provider);
    }


    get ceoSigner(): TestSigner {
        return this._ceoSigner;
    }

    get ctoSigner(): TestSigner {
        return this._ctoSigner;
    }

    get cfoSigner(): TestSigner {
        return this._cfoSigner;
    }

    get investorSigner(): TestSigner {
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