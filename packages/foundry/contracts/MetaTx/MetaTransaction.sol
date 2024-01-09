//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./EIP712Base.sol";
import {console2} from "forge-std/console2.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract EIP712MetaTransaction is EIP712Base {
    using ECDSA for bytes32;
    bytes32 private constant META_TRANSACTION_TYPEHASH = keccak256(bytes("MetaTransaction(uint256 nonce,address from,bytes functionSignature)"));

    event MetaTransactionExecuted(address userAddress, address relayerAddress, bytes functionSignature);
    mapping(address => uint256) private nonces;

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    constructor(string memory name, string memory version) EIP712Base(name, version) {}

    function convertBytesToBytes4(bytes memory inBytes) internal pure returns (bytes4 outBytes4) {
        if (inBytes.length == 0) {
            return 0x0;
        }

        assembly {
            outBytes4 := mload(add(inBytes, 32))
        }
    }

    function executeMetaTransaction(address _contract, address userAddress,
        bytes memory functionSignature, uint8 sigV, bytes32 sigR, bytes32 sigS) public payable returns(bytes memory) {
        bytes4 destinationFunctionSig = convertBytesToBytes4(functionSignature);
        console2.logBytes4(destinationFunctionSig);
        require(destinationFunctionSig != msg.sig, "functionSignature can not be of executeMetaTransaction method");

        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature
        });

        require(verify(userAddress, metaTx, sigR, sigS, sigV), "Signer and signature do not match");
        nonces[userAddress] = nonces[userAddress] + 1;

        // Append userAddress at the end to extract it from calling context
        (bool success, bytes memory returnData) = _contract.call(abi.encodePacked(functionSignature, userAddress));

        if(!success) {
            assembly {
                revert(add(returnData,32),mload(returnData))
            }
        }

        require(success, "Function call not successful");
        emit MetaTransactionExecuted(userAddress, msg.sender, functionSignature);

        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            META_TRANSACTION_TYPEHASH,
            metaTx.nonce,
            metaTx.from,
            keccak256(metaTx.functionSignature)
        ));
    }

    function getNonce(address user) external view returns(uint256 nonce) {
        nonce = nonces[user];
    }

    function verify(address user, MetaTransaction memory metaTx, bytes32 sigR, bytes32 sigS, uint8 sigV) internal view returns (bool) {
        address signer = ECDSA.recover(toTypedMessageHash(hashMetaTransaction(metaTx)), sigV, sigR, sigS);
        require(signer != address(0), "Invalid signature");
        console2.log('signer', signer);
        console2.log('user', user);
        return signer == user;
    }
}