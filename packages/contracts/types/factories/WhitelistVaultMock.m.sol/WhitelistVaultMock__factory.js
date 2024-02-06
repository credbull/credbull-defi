"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.WhitelistVaultMock__factory = void 0;
/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
const ethers_1 = require("ethers");
const _abi = [
    {
        inputs: [
            {
                components: [
                    {
                        internalType: "address",
                        name: "owner",
                        type: "address",
                    },
                    {
                        internalType: "address",
                        name: "operator",
                        type: "address",
                    },
                    {
                        internalType: "contract IERC20",
                        name: "asset",
                        type: "address",
                    },
                    {
                        internalType: "string",
                        name: "shareName",
                        type: "string",
                    },
                    {
                        internalType: "string",
                        name: "shareSymbol",
                        type: "string",
                    },
                    {
                        internalType: "uint256",
                        name: "promisedYield",
                        type: "uint256",
                    },
                    {
                        internalType: "uint256",
                        name: "depositOpensAt",
                        type: "uint256",
                    },
                    {
                        internalType: "uint256",
                        name: "depositClosesAt",
                        type: "uint256",
                    },
                    {
                        internalType: "uint256",
                        name: "redemptionOpensAt",
                        type: "uint256",
                    },
                    {
                        internalType: "uint256",
                        name: "redemptionClosesAt",
                        type: "uint256",
                    },
                    {
                        internalType: "address",
                        name: "custodian",
                        type: "address",
                    },
                    {
                        internalType: "address",
                        name: "kycProvider",
                        type: "address",
                    },
                    {
                        internalType: "address",
                        name: "treasury",
                        type: "address",
                    },
                    {
                        internalType: "address",
                        name: "activityReward",
                        type: "address",
                    },
                ],
                internalType: "struct ICredbull.VaultParams",
                name: "params",
                type: "tuple",
            },
        ],
        stateMutability: "nonpayable",
        type: "constructor",
    },
    {
        inputs: [
            {
                internalType: "address",
                name: "target",
                type: "address",
            },
        ],
        name: "AddressEmptyCode",
        type: "error",
    },
    {
        inputs: [
            {
                internalType: "address",
                name: "account",
                type: "address",
            },
        ],
        name: "AddressInsufficientBalance",
        type: "error",
    },
    {
        inputs: [],
        name: "CredbullVault__NotAWhitelistedAddress",
        type: "error",
    },
    {
        inputs: [
            {
                internalType: "address",
                name: "spender",
                type: "address",
            },
            {
                internalType: "uint256",
                name: "allowance",
                type: "uint256",
            },
            {
                internalType: "uint256",
                name: "needed",
                type: "uint256",
            },
        ],
        name: "ERC20InsufficientAllowance",
        type: "error",
    },
    {
        inputs: [
            {
                internalType: "address",
                name: "sender",
                type: "address",
            },
            {
                internalType: "uint256",
                name: "balance",
                type: "uint256",
            },
            {
                internalType: "uint256",
                name: "needed",
                type: "uint256",
            },
        ],
        name: "ERC20InsufficientBalance",
        type: "error",
    },
    {
        inputs: [
            {
                internalType: "address",
                name: "approver",
                type: "address",
            },
        ],
        name: "ERC20InvalidApprover",
        type: "error",
    },
    {
        inputs: [
            {
                internalType: "address",
                name: "receiver",
                type: "address",
            },
        ],
        name: "ERC20InvalidReceiver",
        type: "error",
    },
    {
        inputs: [
            {
                internalType: "address",
                name: "sender",
                type: "address",
            },
        ],
        name: "ERC20InvalidSender",
        type: "error",
    },
    {
        inputs: [
            {
                internalType: "address",
                name: "spender",
                type: "address",
            },
        ],
        name: "ERC20InvalidSpender",
        type: "error",
    },
    {
        inputs: [
            {
                internalType: "address",
                name: "receiver",
                type: "address",
            },
            {
                internalType: "uint256",
                name: "assets",
                type: "uint256",
            },
            {
                internalType: "uint256",
                name: "max",
                type: "uint256",
            },
        ],
        name: "ERC4626ExceededMaxDeposit",
        type: "error",
    },
    {
        inputs: [
            {
                internalType: "address",
                name: "receiver",
                type: "address",
            },
            {
                internalType: "uint256",
                name: "shares",
                type: "uint256",
            },
            {
                internalType: "uint256",
                name: "max",
                type: "uint256",
            },
        ],
        name: "ERC4626ExceededMaxMint",
        type: "error",
    },
    {
        inputs: [
            {
                internalType: "address",
                name: "owner",
                type: "address",
            },
            {
                internalType: "uint256",
                name: "shares",
                type: "uint256",
            },
            {
                internalType: "uint256",
                name: "max",
                type: "uint256",
            },
        ],
        name: "ERC4626ExceededMaxRedeem",
        type: "error",
    },
    {
        inputs: [
            {
                internalType: "address",
                name: "owner",
                type: "address",
            },
            {
                internalType: "uint256",
                name: "assets",
                type: "uint256",
            },
            {
                internalType: "uint256",
                name: "max",
                type: "uint256",
            },
        ],
        name: "ERC4626ExceededMaxWithdraw",
        type: "error",
    },
    {
        inputs: [],
        name: "FailedInnerCall",
        type: "error",
    },
    {
        inputs: [],
        name: "MathOverflowedMulDiv",
        type: "error",
    },
    {
        inputs: [
            {
                internalType: "address",
                name: "token",
                type: "address",
            },
        ],
        name: "SafeERC20FailedOperation",
        type: "error",
    },
    {
        anonymous: false,
        inputs: [
            {
                indexed: true,
                internalType: "address",
                name: "owner",
                type: "address",
            },
            {
                indexed: true,
                internalType: "address",
                name: "spender",
                type: "address",
            },
            {
                indexed: false,
                internalType: "uint256",
                name: "value",
                type: "uint256",
            },
        ],
        name: "Approval",
        type: "event",
    },
    {
        anonymous: false,
        inputs: [
            {
                indexed: true,
                internalType: "address",
                name: "sender",
                type: "address",
            },
            {
                indexed: true,
                internalType: "address",
                name: "owner",
                type: "address",
            },
            {
                indexed: false,
                internalType: "uint256",
                name: "assets",
                type: "uint256",
            },
            {
                indexed: false,
                internalType: "uint256",
                name: "shares",
                type: "uint256",
            },
        ],
        name: "Deposit",
        type: "event",
    },
    {
        anonymous: false,
        inputs: [
            {
                indexed: true,
                internalType: "address",
                name: "from",
                type: "address",
            },
            {
                indexed: true,
                internalType: "address",
                name: "to",
                type: "address",
            },
            {
                indexed: false,
                internalType: "uint256",
                name: "value",
                type: "uint256",
            },
        ],
        name: "Transfer",
        type: "event",
    },
    {
        anonymous: false,
        inputs: [
            {
                indexed: true,
                internalType: "address",
                name: "sender",
                type: "address",
            },
            {
                indexed: true,
                internalType: "address",
                name: "receiver",
                type: "address",
            },
            {
                indexed: true,
                internalType: "address",
                name: "owner",
                type: "address",
            },
            {
                indexed: false,
                internalType: "uint256",
                name: "assets",
                type: "uint256",
            },
            {
                indexed: false,
                internalType: "uint256",
                name: "shares",
                type: "uint256",
            },
        ],
        name: "Withdraw",
        type: "event",
    },
    {
        inputs: [
            {
                internalType: "address",
                name: "owner",
                type: "address",
            },
            {
                internalType: "address",
                name: "spender",
                type: "address",
            },
        ],
        name: "allowance",
        outputs: [
            {
                internalType: "uint256",
                name: "",
                type: "uint256",
            },
        ],
        stateMutability: "view",
        type: "function",
    },
    {
        inputs: [
            {
                internalType: "address",
                name: "spender",
                type: "address",
            },
            {
                internalType: "uint256",
                name: "value",
                type: "uint256",
            },
        ],
        name: "approve",
        outputs: [
            {
                internalType: "bool",
                name: "",
                type: "bool",
            },
        ],
        stateMutability: "nonpayable",
        type: "function",
    },
    {
        inputs: [],
        name: "asset",
        outputs: [
            {
                internalType: "address",
                name: "",
                type: "address",
            },
        ],
        stateMutability: "view",
        type: "function",
    },
    {
        inputs: [
            {
                internalType: "address",
                name: "account",
                type: "address",
            },
        ],
        name: "balanceOf",
        outputs: [
            {
                internalType: "uint256",
                name: "",
                type: "uint256",
            },
        ],
        stateMutability: "view",
        type: "function",
    },
    {
        inputs: [],
        name: "checkWhitelist",
        outputs: [
            {
                internalType: "bool",
                name: "",
                type: "bool",
            },
        ],
        stateMutability: "view",
        type: "function",
    },
    {
        inputs: [
            {
                internalType: "uint256",
                name: "shares",
                type: "uint256",
            },
        ],
        name: "convertToAssets",
        outputs: [
            {
                internalType: "uint256",
                name: "",
                type: "uint256",
            },
        ],
        stateMutability: "view",
        type: "function",
    },
    {
        inputs: [
            {
                internalType: "uint256",
                name: "assets",
                type: "uint256",
            },
        ],
        name: "convertToShares",
        outputs: [
            {
                internalType: "uint256",
                name: "",
                type: "uint256",
            },
        ],
        stateMutability: "view",
        type: "function",
    },
    {
        inputs: [],
        name: "custodian",
        outputs: [
            {
                internalType: "address",
                name: "",
                type: "address",
            },
        ],
        stateMutability: "view",
        type: "function",
    },
    {
        inputs: [],
        name: "decimals",
        outputs: [
            {
                internalType: "uint8",
                name: "",
                type: "uint8",
            },
        ],
        stateMutability: "view",
        type: "function",
    },
    {
        inputs: [
            {
                internalType: "uint256",
                name: "assets",
                type: "uint256",
            },
            {
                internalType: "address",
                name: "receiver",
                type: "address",
            },
        ],
        name: "deposit",
        outputs: [
            {
                internalType: "uint256",
                name: "",
                type: "uint256",
            },
        ],
        stateMutability: "nonpayable",
        type: "function",
    },
    {
        inputs: [],
        name: "kycProvider",
        outputs: [
            {
                internalType: "contract AKYCProvider",
                name: "",
                type: "address",
            },
        ],
        stateMutability: "view",
        type: "function",
    },
    {
        inputs: [
            {
                internalType: "address",
                name: "",
                type: "address",
            },
        ],
        name: "maxDeposit",
        outputs: [
            {
                internalType: "uint256",
                name: "",
                type: "uint256",
            },
        ],
        stateMutability: "view",
        type: "function",
    },
    {
        inputs: [
            {
                internalType: "address",
                name: "",
                type: "address",
            },
        ],
        name: "maxMint",
        outputs: [
            {
                internalType: "uint256",
                name: "",
                type: "uint256",
            },
        ],
        stateMutability: "view",
        type: "function",
    },
    {
        inputs: [
            {
                internalType: "address",
                name: "owner",
                type: "address",
            },
        ],
        name: "maxRedeem",
        outputs: [
            {
                internalType: "uint256",
                name: "",
                type: "uint256",
            },
        ],
        stateMutability: "view",
        type: "function",
    },
    {
        inputs: [
            {
                internalType: "address",
                name: "owner",
                type: "address",
            },
        ],
        name: "maxWithdraw",
        outputs: [
            {
                internalType: "uint256",
                name: "",
                type: "uint256",
            },
        ],
        stateMutability: "view",
        type: "function",
    },
    {
        inputs: [
            {
                internalType: "uint256",
                name: "shares",
                type: "uint256",
            },
            {
                internalType: "address",
                name: "receiver",
                type: "address",
            },
        ],
        name: "mint",
        outputs: [
            {
                internalType: "uint256",
                name: "",
                type: "uint256",
            },
        ],
        stateMutability: "nonpayable",
        type: "function",
    },
    {
        inputs: [],
        name: "name",
        outputs: [
            {
                internalType: "string",
                name: "",
                type: "string",
            },
        ],
        stateMutability: "view",
        type: "function",
    },
    {
        inputs: [
            {
                internalType: "uint256",
                name: "assets",
                type: "uint256",
            },
        ],
        name: "previewDeposit",
        outputs: [
            {
                internalType: "uint256",
                name: "",
                type: "uint256",
            },
        ],
        stateMutability: "view",
        type: "function",
    },
    {
        inputs: [
            {
                internalType: "uint256",
                name: "shares",
                type: "uint256",
            },
        ],
        name: "previewMint",
        outputs: [
            {
                internalType: "uint256",
                name: "",
                type: "uint256",
            },
        ],
        stateMutability: "view",
        type: "function",
    },
    {
        inputs: [
            {
                internalType: "uint256",
                name: "shares",
                type: "uint256",
            },
        ],
        name: "previewRedeem",
        outputs: [
            {
                internalType: "uint256",
                name: "",
                type: "uint256",
            },
        ],
        stateMutability: "view",
        type: "function",
    },
    {
        inputs: [
            {
                internalType: "uint256",
                name: "assets",
                type: "uint256",
            },
        ],
        name: "previewWithdraw",
        outputs: [
            {
                internalType: "uint256",
                name: "",
                type: "uint256",
            },
        ],
        stateMutability: "view",
        type: "function",
    },
    {
        inputs: [
            {
                internalType: "uint256",
                name: "shares",
                type: "uint256",
            },
            {
                internalType: "address",
                name: "receiver",
                type: "address",
            },
            {
                internalType: "address",
                name: "owner",
                type: "address",
            },
        ],
        name: "redeem",
        outputs: [
            {
                internalType: "uint256",
                name: "",
                type: "uint256",
            },
        ],
        stateMutability: "nonpayable",
        type: "function",
    },
    {
        inputs: [],
        name: "symbol",
        outputs: [
            {
                internalType: "string",
                name: "",
                type: "string",
            },
        ],
        stateMutability: "view",
        type: "function",
    },
    {
        inputs: [
            {
                internalType: "bool",
                name: "status",
                type: "bool",
            },
        ],
        name: "toggleWhitelistCheck",
        outputs: [],
        stateMutability: "nonpayable",
        type: "function",
    },
    {
        inputs: [],
        name: "totalAssetDeposited",
        outputs: [
            {
                internalType: "uint256",
                name: "",
                type: "uint256",
            },
        ],
        stateMutability: "view",
        type: "function",
    },
    {
        inputs: [],
        name: "totalAssets",
        outputs: [
            {
                internalType: "uint256",
                name: "",
                type: "uint256",
            },
        ],
        stateMutability: "view",
        type: "function",
    },
    {
        inputs: [],
        name: "totalSupply",
        outputs: [
            {
                internalType: "uint256",
                name: "",
                type: "uint256",
            },
        ],
        stateMutability: "view",
        type: "function",
    },
    {
        inputs: [
            {
                internalType: "address",
                name: "to",
                type: "address",
            },
            {
                internalType: "uint256",
                name: "value",
                type: "uint256",
            },
        ],
        name: "transfer",
        outputs: [
            {
                internalType: "bool",
                name: "",
                type: "bool",
            },
        ],
        stateMutability: "nonpayable",
        type: "function",
    },
    {
        inputs: [
            {
                internalType: "address",
                name: "from",
                type: "address",
            },
            {
                internalType: "address",
                name: "to",
                type: "address",
            },
            {
                internalType: "uint256",
                name: "value",
                type: "uint256",
            },
        ],
        name: "transferFrom",
        outputs: [
            {
                internalType: "bool",
                name: "",
                type: "bool",
            },
        ],
        stateMutability: "nonpayable",
        type: "function",
    },
    {
        inputs: [
            {
                internalType: "uint256",
                name: "assets",
                type: "uint256",
            },
            {
                internalType: "address",
                name: "receiver",
                type: "address",
            },
            {
                internalType: "address",
                name: "owner",
                type: "address",
            },
        ],
        name: "withdraw",
        outputs: [
            {
                internalType: "uint256",
                name: "",
                type: "uint256",
            },
        ],
        stateMutability: "nonpayable",
        type: "function",
    },
];
const _bytecode = "0x60c06040523480156200001157600080fd5b5060405162001a3b38038062001a3b8339810160408190526200003491620002eb565b8061016001518180604001518160600151826080015181600390816200005b9190620004df565b5060046200006a8282620004df565b5050506000806200008183620000f060201b60201c565b91509150816200009357601262000095565b805b60ff1660a05250506001600160a01b0390811660805261014090910151600580549183166001600160a01b0319909216919091179055600780546001600160a81b0319169290911691909117600160a01b17905550620005e3565b60408051600481526024810182526020810180516001600160e01b031663313ce56760e01b17905290516000918291829182916001600160a01b038716916200013991620005ab565b600060405180830381855afa9150503d806000811462000176576040519150601f19603f3d011682016040523d82523d6000602084013e6200017b565b606091505b50915091508180156200019057506020815110155b15620001c857600081806020019051810190620001ae9190620005c9565b905060ff8111620001c6576001969095509350505050565b505b5060009485945092505050565b634e487b7160e01b600052604160045260246000fd5b6040516101c081016001600160401b0381118282101715620002115762000211620001d5565b60405290565b80516001600160a01b03811681146200022f57600080fd5b919050565b60005b838110156200025157818101518382015260200162000237565b50506000910152565b600082601f8301126200026c57600080fd5b81516001600160401b0380821115620002895762000289620001d5565b604051601f8301601f19908116603f01168101908282118183101715620002b457620002b4620001d5565b81604052838152866020858801011115620002ce57600080fd5b620002e184602083016020890162000234565b9695505050505050565b600060208284031215620002fe57600080fd5b81516001600160401b03808211156200031657600080fd5b908301906101c082860312156200032c57600080fd5b62000336620001eb565b620003418362000217565b8152620003516020840162000217565b6020820152620003646040840162000217565b60408201526060830151828111156200037c57600080fd5b6200038a878286016200025a565b606083015250608083015182811115620003a357600080fd5b620003b1878286016200025a565b60808301525060a0838101519082015260c0808401519082015260e08084015190820152610100808401519082015261012080840151908201526101409150620003fd82840162000217565b8282015261016091506200041382840162000217565b8282015261018091506200042982840162000217565b828201526101a091506200043f82840162000217565b91810191909152949350505050565b600181811c908216806200046357607f821691505b6020821081036200048457634e487b7160e01b600052602260045260246000fd5b50919050565b601f821115620004da576000816000526020600020601f850160051c81016020861015620004b55750805b601f850160051c820191505b81811015620004d657828155600101620004c1565b5050505b505050565b81516001600160401b03811115620004fb57620004fb620001d5565b62000513816200050c84546200044e565b846200048a565b602080601f8311600181146200054b5760008415620005325750858301515b600019600386901b1c1916600185901b178555620004d6565b600085815260208120601f198616915b828110156200057c578886015182559484019460019091019084016200055b565b50858210156200059b5787850151600019600388901b60f8161c191681555b5050505050600190811b01905550565b60008251620005bf81846020870162000234565b9190910192915050565b600060208284031215620005dc57600080fd5b5051919050565b60805160a0516114246200061760003960006105560152600081816102d301528181610845015261092a01526114246000f3fe608060405234801561001057600080fd5b50600436106101da5760003560e01c806370a0823111610104578063ba087652116100a2578063d905777e11610071578063d905777e146103e8578063dd62ed3e146103fb578063ef8b30f7146103c2578063f85a609e1461043457600080fd5b8063ba087652146103af578063c63d75b6146102f7578063c6e6f592146103c2578063ce96cb77146103d557600080fd5b8063a26c786f116100de578063a26c786f14610363578063a9059cbb14610376578063b3d7f6b914610389578063b460af941461039c57600080fd5b806370a082311461031f57806394bf804d1461034857806395d89b411461035b57600080fd5b806318160ddd1161017c57806338d52e0f1161014b57806338d52e0f146102d1578063402d267d146102f75780634cdad5061461022f5780636e553f651461030c57600080fd5b806318160ddd1461027157806323b872dd14610279578063313ce5671461028c578063375b74c3146102a657600080fd5b806307a2d13a116101b857806307a2d13a1461022f578063095ea7b3146102425780630a28a4771461025557806312279b7c1461026857600080fd5b806301e1d114146101df57806306f2057a146101f657806306fdde031461021a575b600080fd5b6006545b6040519081526020015b60405180910390f35b60075461020a90600160a01b900460ff1681565b60405190151581526020016101ed565b61022261045e565b6040516101ed9190611010565b6101e361023d366004611043565b6104f0565b61020a610250366004611078565b610503565b6101e3610263366004611043565b61051b565b6101e360065481565b6002546101e3565b61020a6102873660046110a2565b610528565b61029461054e565b60405160ff90911681526020016101ed565b6005546102b9906001600160a01b031681565b6040516001600160a01b0390911681526020016101ed565b7f00000000000000000000000000000000000000000000000000000000000000006102b9565b6101e36103053660046110de565b5060001990565b6101e361031a3660046110f9565b61057f565b6101e361032d3660046110de565b6001600160a01b031660009081526020819052604090205490565b6101e36103563660046110f9565b6105b3565b6102226105d1565b6007546102b9906001600160a01b031681565b61020a610384366004611078565b6105e0565b6101e3610397366004611043565b6105ee565b6101e36103aa366004611125565b6105fb565b6101e36103bd366004611125565b610653565b6101e36103d0366004611043565b6106a2565b6101e36103e33660046110de565b6106af565b6101e36103f63660046110de565b6106d3565b6101e3610409366004611161565b6001600160a01b03918216600090815260016020908152604080832093909416825291909152205490565b61045c610442366004611199565b6007805460ff60a01b1916600160a01b8315150217905550565b005b60606003805461046d906111b6565b80601f0160208091040260200160405190810160405280929190818152602001828054610499906111b6565b80156104e65780601f106104bb576101008083540402835291602001916104e6565b820191906000526020600020905b8154815290600101906020018083116104c957829003601f168201915b5050505050905090565b60006104fd8260006106f4565b92915050565b60003361051181858561072f565b5060019392505050565b60006104fd826001610741565b60003361053685828561076c565b6105418585856107d7565b60019150505b9392505050565b600061057a817f0000000000000000000000000000000000000000000000000000000000000000611206565b905090565b6000600019610592565b60405180910390fd5b600061059d856106a2565b90506105ab33858784610836565b949350505050565b600060001960006105c3856105ee565b90506105ab33858388610836565b60606004805461046d906111b6565b6000336105118185856107d7565b60006104fd8260016106f4565b600080610607836106af565b90508085111561063057828582604051633fa733bb60e21b81526004016105899392919061121f565b600061063b8661051b565b905061064a33868689856108f7565b95945050505050565b60008061065f836106d3565b90508085111561068857828582604051632e52afbb60e21b81526004016105899392919061121f565b6000610693866104f0565b905061064a338686848a6108f7565b60006104fd826000610741565b6001600160a01b0381166000908152602081905260408120546104fd9060006106f4565b6001600160a01b0381166000908152602081905260408120546104fd565b50565b600061054761070260065490565b61070d906001611240565b6107196000600a611337565b6002546107269190611240565b859190856109bb565b61073c8383836001610a0a565b505050565b600061054761075182600a611337565b60025461075e9190611240565b600654610726906001611240565b6001600160a01b0383811660009081526001602090815260408083209386168352929052205460001981146107d157818110156107c257828183604051637dc7a0d960e11b81526004016105899392919061121f565b6107d184848484036000610a0a565b50505050565b6001600160a01b03831661080157604051634b637e8f60e11b815260006004820152602401610589565b6001600160a01b03821661082b5760405163ec442f0560e01b815260006004820152602401610589565b61073c838383610adf565b8261084081610bf6565b6108787f000000000000000000000000000000000000000000000000000000000000000060055487906001600160a01b031686610c98565b826006600082825461088a9190611240565b9091555061089a90508483610cff565b836001600160a01b0316856001600160a01b03167fdcbc1c05240f31ff3ad067ef1ee35ce4997762752e3a095284754544f4c709d785856040516108e8929190918252602082015260400190565b60405180910390a35050505050565b826001600160a01b0316856001600160a01b03161461091b5761091b83868361076c565b6109258382610d39565b6109507f00000000000000000000000000000000000000000000000000000000000000008584610d6f565b81600660008282546109629190611346565b909155505060408051838152602081018390526001600160a01b038086169287821692918916917ffbde797d201c681b91056529119e0b02407c7bb96a4a2c75c01fc9667232c8db910160405180910390a45050505050565b6000806109c9868686610da0565b90506109d483610e64565b80156109f05750600084806109eb576109eb611359565b868809115b1561064a57610a00600182611240565b9695505050505050565b6001600160a01b038416610a345760405163e602df0560e01b815260006004820152602401610589565b6001600160a01b038316610a5e57604051634a1406b160e11b815260006004820152602401610589565b6001600160a01b03808516600090815260016020908152604080832093871683529290522082905580156107d157826001600160a01b0316846001600160a01b03167f8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b92584604051610ad191815260200190565b60405180910390a350505050565b6001600160a01b038316610b0a578060026000828254610aff9190611240565b90915550610b699050565b6001600160a01b03831660009081526020819052604090205481811015610b4a5783818360405163391434e360e21b81526004016105899392919061121f565b6001600160a01b03841660009081526020819052604090209082900390555b6001600160a01b038216610b8557600280548290039055610ba4565b6001600160a01b03821660009081526020819052604090208054820190555b816001600160a01b0316836001600160a01b03167fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef83604051610be991815260200190565b60405180910390a3505050565b600754600160a01b900460ff168015610c7a575060075460405163645b8b1b60e01b81526001600160a01b0383811660048301529091169063645b8b1b90602401602060405180830381865afa158015610c54573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190610c78919061136f565b155b156106f157604051636ecc5bb160e11b815260040160405180910390fd5b6040516001600160a01b0384811660248301528381166044830152606482018390526107d19186918216906323b872dd906084015b604051602081830303815290604052915060e01b6020820180516001600160e01b038381831617835250505050610e91565b6001600160a01b038216610d295760405163ec442f0560e01b815260006004820152602401610589565b610d3560008383610adf565b5050565b6001600160a01b038216610d6357604051634b637e8f60e11b815260006004820152602401610589565b610d3582600083610adf565b6040516001600160a01b0383811660248301526044820183905261073c91859182169063a9059cbb90606401610ccd565b6000838302816000198587098281108382030391505080600003610dd757838281610dcd57610dcd611359565b0492505050610547565b808411610df75760405163227bc15360e01b815260040160405180910390fd5b6000848688096000868103871696879004966002600389028118808a02820302808a02820302808a02820302808a02820302808a02820302808a02909103029181900381900460010186841190950394909402919094039290920491909117919091029150509392505050565b60006002826003811115610e7a57610e7a61138c565b610e8491906113a2565b60ff166001149050919050565b6000610ea66001600160a01b03841683610ef4565b90508051600014158015610ecb575080806020019051810190610ec9919061136f565b155b1561073c57604051635274afe760e01b81526001600160a01b0384166004820152602401610589565b60606105478383600084600080856001600160a01b03168486604051610f1a91906113d2565b60006040518083038185875af1925050503d8060008114610f57576040519150601f19603f3d011682016040523d82523d6000602084013e610f5c565b606091505b5091509150610a00868383606082610f7c57610f7782610fc3565b610547565b8151158015610f9357506001600160a01b0384163b155b15610fbc57604051639996b31560e01b81526001600160a01b0385166004820152602401610589565b5080610547565b805115610fd35780518082602001fd5b604051630a12f52160e11b815260040160405180910390fd5b60005b83811015611007578181015183820152602001610fef565b50506000910152565b602081526000825180602084015261102f816040850160208701610fec565b601f01601f19169190910160400192915050565b60006020828403121561105557600080fd5b5035919050565b80356001600160a01b038116811461107357600080fd5b919050565b6000806040838503121561108b57600080fd5b6110948361105c565b946020939093013593505050565b6000806000606084860312156110b757600080fd5b6110c08461105c565b92506110ce6020850161105c565b9150604084013590509250925092565b6000602082840312156110f057600080fd5b6105478261105c565b6000806040838503121561110c57600080fd5b8235915061111c6020840161105c565b90509250929050565b60008060006060848603121561113a57600080fd5b8335925061114a6020850161105c565b91506111586040850161105c565b90509250925092565b6000806040838503121561117457600080fd5b61117d8361105c565b915061111c6020840161105c565b80151581146106f157600080fd5b6000602082840312156111ab57600080fd5b81356105478161118b565b600181811c908216806111ca57607f821691505b6020821081036111ea57634e487b7160e01b600052602260045260246000fd5b50919050565b634e487b7160e01b600052601160045260246000fd5b60ff81811683821601908111156104fd576104fd6111f0565b6001600160a01b039390931683526020830191909152604082015260600190565b808201808211156104fd576104fd6111f0565b600181815b8085111561128e578160001904821115611274576112746111f0565b8085161561128157918102915b93841c9390800290611258565b509250929050565b6000826112a5575060016104fd565b816112b2575060006104fd565b81600181146112c857600281146112d2576112ee565b60019150506104fd565b60ff8411156112e3576112e36111f0565b50506001821b6104fd565b5060208310610133831016604e8410600b8410161715611311575081810a6104fd565b61131b8383611253565b806000190482111561132f5761132f6111f0565b029392505050565b600061054760ff841683611296565b818103818111156104fd576104fd6111f0565b634e487b7160e01b600052601260045260246000fd5b60006020828403121561138157600080fd5b81516105478161118b565b634e487b7160e01b600052602160045260246000fd5b600060ff8316806113c357634e487b7160e01b600052601260045260246000fd5b8060ff84160691505092915050565b600082516113e4818460208701610fec565b919091019291505056fea2646970667358221220893c6bef27faf0aac48c1c0aa0290eed643aec890c55e8438c627d2789a4297e64736f6c63430008160033";
const isSuperArgs = (xs) => xs.length > 1;
class WhitelistVaultMock__factory extends ethers_1.ContractFactory {
    constructor(...args) {
        if (isSuperArgs(args)) {
            super(...args);
        }
        else {
            super(_abi, _bytecode, args[0]);
        }
    }
    deploy(params, overrides) {
        return super.deploy(params, overrides || {});
    }
    getDeployTransaction(params, overrides) {
        return super.getDeployTransaction(params, overrides || {});
    }
    attach(address) {
        return super.attach(address);
    }
    connect(signer) {
        return super.connect(signer);
    }
    static createInterface() {
        return new ethers_1.utils.Interface(_abi);
    }
    static connect(address, signerOrProvider) {
        return new ethers_1.Contract(address, _abi, signerOrProvider);
    }
}
exports.WhitelistVaultMock__factory = WhitelistVaultMock__factory;
WhitelistVaultMock__factory.bytecode = _bytecode;
WhitelistVaultMock__factory.abi = _abi;
