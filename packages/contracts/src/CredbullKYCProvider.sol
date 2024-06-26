// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { KYCProvider } from "./provider/kyc/KYCProvider.sol";

contract CredbullKYCProvider is KYCProvider {
    constructor(address _owner) KYCProvider(_owner) { }
}
