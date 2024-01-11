import { Controller, Get } from '@nestjs/common';
import * as ethSigUtil from 'eth-sig-util';
import { Contract, Signer, utils } from 'ethers';

import { EthersService } from '../../clients/ethers/ethers.service';
import * as ForwarderABI from '../../utils/abi/Forwarder.json';
import * as MetaVaultABI from '../../utils/abi/MetaVault.json';

import { MetaTxService } from './metatx.service';

@Controller('metatx')
export class MetaTxController {
  private signer: Signer;
  constructor(
    private readonly metaTx: MetaTxService,
    private ethers: EthersService,
  ) {
    this.signer = ethers.localDeployer();
  }

  @Get()
  async getData(): Promise<string> {
    return this.metaTx.getData();
  }

  @Get('/chainId')
  async pingNetwork(): Promise<string> {
    return (await this.signer.getChainId()).toString();
  }

  //   @Get('/meta-tx')
  //   async executeMetaTx(): Promise<Boolean> {
  //     //const vault = new Contract("0x8438Ad1C834623CfF278AB6829a248E37C2D7E3f", MetaVaultABI.abi, this.signer);

  //     const AbiCoder = new utils.AbiCoder();
  //     const Interface = new utils.Interface(MetaVaultABI.abi);
  //     const ForwarderInterface = new utils.Interface(ForwarderABI.abi);
  //     const amount = utils.parseEther("100");
  //     const signer = "0x06457f819Bf569DD00DF321740cd4BBDc367872c";
  //     const vault = "0xAD77C8a82E98d86C5c2548F2bCb500a2a23F859D";
  //     const forwarderAddr = "0x5e3f195cf47218222d50296b79785c8d2F693204";

  //     const forwarder = new Contract(forwarderAddr, ForwarderABI.abi, this.signer);

  //     const functionSignature = Interface.encodeFunctionData('deposit', [amount, signer]);
  //     // console.log(functionSignature);

  //     // console.log(AbiCoder.encode(
  //     //     ['string', 'string', 'uint256', 'address'],
  //     //     [utils.keccak256(utils.toUtf8Bytes("Cred")), utils.keccak256(utils.toUtf8Bytes("1")), 5777, forwarderAddr]
  //     //  ));
  //     const typeHash = "0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f";

  //     console.log('cred bytes', utils.hexlify(utils.toUtf8Bytes("Cred")));

  //     console.log(utils.defaultAbiCoder.encode(["bytes32", "string", "string", "uint256", "address"], [typeHash, utils.keccak256(utils.hexlify(utils.toUtf8Bytes("Cred"))), utils.keccak256(utils.hexlify(utils.toUtf8Bytes("1"))), 5777, forwarderAddr]));

  //     //const functionSignature = AbiCoder.encode(['uint256', 'address'], [amount, signer]);
  //     const domainSeparator = utils.keccak256(
  //         AbiCoder.encode(
  //            ['string', 'string', 'uint256', 'address'],
  //            [utils.keccak256(utils.toUtf8Bytes("Cred")), utils.keccak256(utils.toUtf8Bytes("1")), 5777, forwarderAddr]
  //         )
  //     );

  //     const nonce = await forwarder.nonces(signer);

  //     const encodedData = utils.keccak256(AbiCoder.encode(
  //         ['address', 'address', 'uint256', 'uint256', 'uint256', 'uint48', 'bytes'],
  //         [signer, vault, 0, 100000,  nonce, 100000, functionSignature]
  //     ));

  //     const hash = utils.keccak256(
  //         AbiCoder.encode(
  //             ['string', 'bytes', 'bytes'],
  //             ["\x19\x01", domainSeparator, encodedData]
  //         )
  //     );

  //     // Sign the meta transaction
  //     // const signature = await this.signer.(
  //     //     { primaryType: "MetaTransaction", domain: { name: "MyContract", version: "1", chainId: 1, verifyingContract: myContractAddress }, types: { MetaTransaction: [{ name: "from", type: "address" }, { name: "functionSelector", type: "bytes4" }, { name: "data", type: "bytes" }] } }, value: { from: signer.address, functionSelector: myContract.interface.getSighash("myFunction"), data: data } }
  //     // );

  //     // const signature = await this.signer.(hash);
  //     //console.log(signature);

  //     // const requestStruct = {
  //     //     from: signer,
  //     //     to: vault,
  //     //     value: 0,
  //     //     gas: 100_000,
  //     //     deadline: 100_000_000_0,
  //     //     data: functionSignature,
  //     //     signature: signature
  //     // }

  //     // console.log(await forwarder.verify(requestStruct));
  //     // const result = await forwarder.execute(requestStruct, {
  //     //     gasLimit: requestStruct.gas
  //     // });

  //     // const receipt = await result.wait();

  //     // console.log(receipt);

  //     return true;
  //   }

  @Get('/meta-tx')
  async executeMetaTx(): Promise<boolean> {
    const EIP712Domain = [
      { name: 'name', type: 'string' },
      { name: 'version', type: 'string' },
      { name: 'chainId', type: 'uint256' },
      { name: 'verifyingContract', type: 'address' },
    ];

    const ForwardRequest = [
      { name: 'from', type: 'address' },
      { name: 'to', type: 'address' },
      { name: 'value', type: 'uint256' },
      { name: 'gas', type: 'uint256' },
      { name: 'nonce', type: 'uint256' },
      { name: 'data', type: 'bytes' },
    ];

    const vault = new Contract('0xAD77C8a82E98d86C5c2548F2bCb500a2a23F859D', MetaVaultABI.abi, this.signer);
    // const AbiCoder = new utils.AbiCoder();
    // const Interface = new utils.Interface(MetaVaultABI.abi);
    // const ForwarderInterface = new utils.Interface(ForwarderABI.abi);
    const amount = utils.parseEther('100');
    console.log('amount', amount);
    const signer = '0x06457f819Bf569DD00DF321740cd4BBDc367872c';
    const vaultAddr = '0xAD77C8a82E98d86C5c2548F2bCb500a2a23F859D';
    const forwarderAddr = '0x5e3f195cf47218222d50296b79785c8d2F693204';

    const forwarder = new Contract(forwarderAddr, ForwarderABI.abi, this.signer);

    const input = {
      from: signer,
      to: vaultAddr,
      data: vault.interface.encodeFunctionData('deposit', [amount, signer]),
    };
    const nonce = await forwarder.nonces(signer);
    console.log(typeof parseInt(nonce.toString()));
    const request = {
      value: 0,
      gas: 1000000,
      deadline: 1_000_000_000,
      nonce: parseInt(await forwarder.nonces(signer).toString()),
      ...input,
    };

    console.log(await forwarder.provider.getNetwork().then((n) => n.chainId));

    const toSign = {
      types: {
        EIP712Domain,
        ForwardRequest,
      },
      domain: {
        name: 'Cred',
        version: '1',
        chainId: 1337,
        verifyingContract: forwarderAddr,
      },
      primaryType: 'ForwardRequest',
      message: request,
    };

    //@ts-expect-error: Expect different type
    const signature = ethSigUtil.signTypedData_v4(
      Buffer.from('d73e8ac07f751dc7d1ebe884ca222ecafc771ea51c81febe998074ab7e5b650c', 'hex'),
      { data: toSign },
    );

    console.log(signature);

    const forwardRequest = {
      from: request.from,
      to: request.to,
      value: request.value,
      gas: request.gas,
      deadline: request.deadline,
      data: request.data,
      signature,
    };

    const result = await forwarder.verify(forwardRequest);
    console.log(result);

    return result;
  }
}
