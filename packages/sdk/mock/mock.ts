import { CredbullSDK } from "..";
import { linkWalletMessage, login, signer } from './utils/helpers';
import { BigNumber } from 'ethers';
import { MockStablecoin__factory  } from "@credbull/contracts";
import { config } from 'dotenv';

config();

(async() => {
    //Login to get access token
    const res = await login('krishnakumar@ascent-hr', '1.ql8lo3qdok');
    //Signer or Provider
    const userSigner = signer(process.env.ADMIN_PRIVATE_KEY || "0x");

    // Initialize the SDK
    const sdk =  new CredbullSDK(res.access_token, userSigner);

    //Get all vaults through SDK
    const vaults = await sdk.getAllVaults();
    console.log(vaults);

    const message = await linkWalletMessage(userSigner);
    const signature = await userSigner.signMessage(message);

    //Link wallet through SDK
    await sdk.linkWallet(message, signature);
  
    //Prepare for deposit
    const vaultAddress = vaults.data ? vaults.data[0].address : "";
    const depositAmount = BigNumber.from('100000000');

    const assetAddress = await sdk.getAssetAddress(vaultAddress);

    const usdc = MockStablecoin__factory.connect(assetAddress, userSigner);
    await usdc.mint(userSigner.address, depositAmount);
    await usdc.approve(vaultAddress, depositAmount);
    
    //Deposit through SDK
    await sdk.deposit(vaultAddress, depositAmount);

    const shares = BigNumber.from('100000000');
    const vault = await sdk.getVaultInstance(vaultAddress);


    console.log((await vault.balanceOf(userSigner.address)).toString());

    await usdc.mint(vaultAddress, depositAmount);
    //Redeem through SDK
    await sdk.redeem(vaultAddress, shares);

    console.log((await vault.balanceOf(userSigner.address)).toString());

})();
