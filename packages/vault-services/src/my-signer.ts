import { providers} from 'ethers';
import {SafeAccountConfig} from "@safe-global/protocol-kit";

export class MySigner {
    private provider: providers.JsonRpcProvider;
    private _delegate: providers.JsonRpcSigner;

    constructor(index:number, provider: providers.JsonRpcProvider) {
        this.provider = provider;
        this._delegate = provider.getSigner(index);
    }

    getAddress():Promise<string> {
        let address = this._delegate.getAddress();

        return address;
    }


    getDelegate(): providers.JsonRpcSigner {
        return this._delegate;
    }
}

export class AllSigners {
    private _ceoSigner: MySigner;
    private _ctoSigner: MySigner;
    private _cfoSigner: MySigner;
    private _investorSigner: MySigner;

    constructor(provider: providers.JsonRpcProvider) {
        this._ceoSigner = new MySigner(0, provider);
        this._cfoSigner = new MySigner(1, provider);
        this._ctoSigner = new MySigner(2,provider);
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