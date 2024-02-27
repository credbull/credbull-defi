import { CredbullSDK } from "..";
import { generateSigner, linkWalletMessage, login, signer } from './utils/helpers';
import { BigNumber, utils } from 'ethers';
import { MockStablecoin__factory  } from "@credbull/contracts";
import { config } from 'dotenv';

config();

(async() => {
    //Login to get access token
    const res = await login('krishnakumar@ascent-hr', '1.ql8lo3qdok');
  
    //Signer or Provider
    //TODO: Replace it with privatekey from env
    const user1Signer = generateSigner();
    const user2Signer = generateSigner();
    const admin = signer(process.env.ADMIN_PRIVATE_KEY || "0x");

    //Send ETH to users to do txns
    const tx1 = {
        to: user1Signer.address,
        value: utils.parseEther('0.01')
    };
    const tx2 = {
        to: user2Signer.address,
        value: utils.parseEther('0.01')
    };
    await admin.sendTransaction(tx1);
    await admin.sendTransaction(tx2);

    // Initialize the SDK
    const sdkUser1 =  new CredbullSDK(res.access_token, user1Signer);
    const sdkUser2 = new CredbullSDK(res.access_token, user2Signer);

    //Get all vaults through SDK
    const vaults = await sdkUser1.getAllVaults();
    console.log(vaults);

    const message1 = await linkWalletMessage(user1Signer);
    const signature1 = await user1Signer.signMessage(message1);

    const message2 = await linkWalletMessage(user2Signer);
    const signature2 = await user1Signer.signMessage(message2);

    //Link wallet through SDK
    await sdkUser1.linkWallet(message1, signature1);
    await sdkUser2.linkWallet(message2, signature2);
  
    //Prepare for deposit
    const vaultAddress = vaults.data ? vaults.data[0].address : "";
    const depositAmount = BigNumber.from('100000000');

    const assetAddress = await sdkUser1.getAssetAddress(vaultAddress);

    const usdc = MockStablecoin__factory.connect(assetAddress, user1Signer);
    await usdc.mint(user1Signer.address, depositAmount);
    await usdc.mint(user2Signer.address, depositAmount);

    await usdc.connect(user1Signer).approve(vaultAddress, depositAmount);
    await usdc.connect(user2Signer).approve(vaultAddress, depositAmount);

    const vault = await sdkUser1.getVaultInstance(vaultAddress);

    //Deposit through SDK
    await sdkUser1.deposit(vaultAddress, depositAmount);
    await sdkUser2.deposit(vaultAddress, depositAmount);
    console.log("========================== Deposit completed! =====================");
    console.log("User1 Shares:", (await vault.balanceOf(user1Signer.address)).toString());
    console.log("User2 Shares:", (await vault.balanceOf(user2Signer.address)).toString());

    const shares = depositAmount;

    await usdc.mint(vaultAddress, depositAmount.mul(2));
    //Skipping window check
    await vault.connect(admin).toggleWindowCheck(false);

    // //Redeem through SDK
    await sdkUser1.redeem(vaultAddress, shares);
    await sdkUser2.redeem(vaultAddress, shares);
    console.log("========================== Redeem completed! =====================");
    console.log("User1 Shares:", (await vault.balanceOf(user1Signer.address)).toString());
    console.log("User2 Shares:", (await vault.balanceOf(user2Signer.address)).toString());
})();
