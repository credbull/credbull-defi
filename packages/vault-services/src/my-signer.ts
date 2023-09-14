import {providers} from 'ethers';

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

