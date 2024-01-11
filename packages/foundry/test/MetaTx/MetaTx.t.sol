// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.19;

// import { Test, console2 } from "forge-std/Test.sol";
// import { MetaVault } from "../../contracts/MetaTx/MetaVault.sol";
// import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import { MockERC20Permit } from "../mocks/MockERC20Permit.sol";
// import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";
// import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
// import { ERC2771Forwarder } from "@openzeppelin/contracts/metatx/ERC2771Forwarder.sol";

// contract MetaTxTest is Test {
//     using MessageHashUtils for bytes32;

//     MetaVault private vault;
//     MockERC20Permit private usdc;
//     ERC2771Forwarder private forwarder;

//     Account private signer;
//     Account private sender;

//     bytes32 private constant PERMIT_TYPEHASH =
//         keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

//     bytes32 private constant _TYPE_HASH =
//         keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

//     bytes32 internal constant _FORWARD_REQUEST_TYPEHASH = keccak256(
//         "ForwardRequest(address from,address to,uint256 value,uint256 gas,uint256 nonce,uint48 deadline,bytes data)"
//     );

//     function getForwardRequestDataSignature(
//         ERC2771Forwarder.ForwardRequestData memory request,
//         uint256 nonce,
//         uint256 privateKey,
//         bytes32 domainSeparator
//     ) internal pure returns (bytes memory sig) {
//         bytes32 msgHash = MessageHashUtils.toTypedDataHash(
//             domainSeparator,
//             keccak256(
//                 abi.encode(
//                     _FORWARD_REQUEST_TYPEHASH,
//                     request.from,
//                     request.to,
//                     request.value,
//                     request.gas,
//                     nonce,
//                     request.deadline,
//                     keccak256(request.data)
//                 )
//             )
//         );
//         (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, msgHash);

//         return bytes.concat(r, s, bytes1(v));
//     }

//     function forwarderDomainSeparator() internal view returns (bytes32) {
//         return keccak256(
//             abi.encode(_TYPE_HASH, keccak256(bytes("Cred")), keccak256(bytes("1")), block.chainid, address(forwarder))
//         );
//     }

//     function setUp() public {
//         signer = makeAccount("signer");
//         sender = makeAccount("sender");

//         usdc = new MockERC20Permit();
//         usdc.mint(signer.addr, 1000 ether);

//         forwarder = new ERC2771Forwarder("Cred");
//         vault = new MetaVault("Test", "t", IERC20(usdc), forwarder);
//     }

//     function testMetaTransaction() public {
//         uint256 amount = 100 ether;
//         bytes memory data = abi.encodeWithSelector(IERC4626.deposit.selector, amount, signer.addr);

//         ERC2771Forwarder.ForwardRequestData memory request = ERC2771Forwarder.ForwardRequestData({
//             from: signer.addr,
//             to: address(vault),
//             value: 0,
//             gas: 100_000,
//             deadline: 100_000,
//             data: data,
//             signature: bytes("")
//         });

//         request.signature = getForwardRequestDataSignature(
//             request, forwarder.nonces(sender.addr), signer.key, forwarderDomainSeparator()
//         );

//         vm.prank(signer.addr);
//         usdc.approve(address(vault), amount);

//         vm.prank(sender.addr);
//         forwarder.execute(request);

//         assertEq(usdc.balanceOf(signer.addr), 900 ether);
//         assertEq(vault.balanceOf(signer.addr), amount);
//     }

//     function testDepositWithPermitAsMetaTransaction() public {
//         uint256 amount = 100 ether;
//         uint256 deadline = block.timestamp + 7 days;

//         bytes32 structHash = keccak256(
//             abi.encode(PERMIT_TYPEHASH, signer.addr, address(vault), amount, usdc.nonces(sender.addr), deadline)
//         );

//         bytes32 msgHash = MessageHashUtils.toTypedDataHash(usdc.DOMAIN_SEPARATOR(), structHash);
//         (uint8 v, bytes32 r, bytes32 s) = vm.sign(signer.key, msgHash);

//         bytes memory data = abi.encodeWithSelector(
//             MetaVault.depositWithPermit.selector, signer.addr, signer.addr, amount, deadline, v, r, s
//         );

//         ERC2771Forwarder.ForwardRequestData memory request = ERC2771Forwarder.ForwardRequestData({
//             from: signer.addr,
//             to: address(vault),
//             value: 0,
//             gas: 100_000_000,
//             deadline: 100_000,
//             data: data,
//             signature: bytes("")
//         });

//         request.signature = getForwardRequestDataSignature(
//             request, forwarder.nonces(sender.addr), signer.key, forwarderDomainSeparator()
//         );

//         vm.prank(sender.addr);
//         forwarder.execute(request);

//         assertEq(usdc.balanceOf(signer.addr), 900 ether);
//         assertEq(vault.balanceOf(signer.addr), amount);
//     }
// }
