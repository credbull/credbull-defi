import Safe, {ContractNetworksConfig, EthersAdapter, SafeAccountConfig, SafeFactory} from "@safe-global/protocol-kit";
import {SafeVersion} from "@safe-global/safe-core-sdk-types";
import {ethers} from "ethers";
import {createContractNetworks} from "./network-config";

export async function deployVault(safeAccountConfig: SafeAccountConfig, ethAdapter: EthersAdapter, safeVersion: SafeVersion): Promise<Safe> {
    var contractNetworks: ContractNetworksConfig = createContractNetworks(await ethAdapter.getChainId(), safeVersion);

    const safeFactory: SafeFactory = await SafeFactory.create({
        ethAdapter: ethAdapter,
        contractNetworks: contractNetworks,
        safeVersion: safeVersion
    });

    // TODO: review nonce behaviour, see const nonce = await safeService.getNextNonce(safeAddress) https://docs.safe.global/reference/api-kit
    const saltNonce: string = Date.now().toString(); // using a salt, otherwise fails on multiple calls (all other params the same)

    const safeSdk: Safe = await safeFactory.deploySafe({safeAccountConfig, saltNonce})

    return safeSdk;
}

export function toEtherHex(value: string) {
    return ethers.utils.parseUnits(value, "ether").toHexString();
}

export function toWei(depositAmountInEther: number): bigint {
    return ethers.BigNumber.from(depositAmountInEther).mul(ethers.constants.WeiPerEther).toBigInt();
}

export async function depositToSafe(provider: ethers.providers.JsonRpcProvider, vaultAddress: string, fromAddress: string, depositValueInEther: number) {
    // create and authorize a transaction
    const params = [{
        from: fromAddress,
        to: vaultAddress,
        value: toEtherHex(depositValueInEther.toString()),
    }];

    return await provider.send("eth_sendTransaction", params);
}