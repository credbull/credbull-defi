/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import { Signer, utils, Contract, ContractFactory, Overrides } from "ethers";
import type { Provider, TransactionRequest } from "@ethersproject/providers";
import type {
  WindowVaultMock,
  WindowVaultMockInterface,
  ICredbull,
} from "../../WindowVaultMock.m.sol/WindowVaultMock";

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
    inputs: [
      {
        internalType: "uint256",
        name: "windowOpensAt",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "windowClosesAt",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "timestamp",
        type: "uint256",
      },
    ],
    name: "CredbullVault__OperationOutsideRequiredWindow",
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
    name: "checkWindow",
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
    name: "depositClosesAtTimestamp",
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
    name: "depositOpensAtTimestamp",
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
    name: "redemptionClosesAtTimestamp",
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
    name: "redemptionOpensAtTimestamp",
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
    name: "toggleWindowCheck",
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
] as const;

const _bytecode =
  "0x60c06040523480156200001157600080fd5b5060405162001a1a38038062001a1a8339810160408190526200003491620002f9565b8060c001518160e001518261010001518361012001518480604001518160600151826080015181600390816200006b9190620004c1565b5060046200007a8282620004c1565b5050506000806200009183620000fe60201b60201c565b9150915081620000a3576012620000a5565b805b60ff1660a05250506001600160a01b039081166080526101409190910151600580546001600160a01b03191691909216179055600793909355600891909155600955600a5550600b805460ff19166001179055620005c5565b60408051600481526024810182526020810180516001600160e01b031663313ce56760e01b17905290516000918291829182916001600160a01b0387169162000147916200058d565b600060405180830381855afa9150503d806000811462000184576040519150601f19603f3d011682016040523d82523d6000602084013e62000189565b606091505b50915091508180156200019e57506020815110155b15620001d657600081806020019051810190620001bc9190620005ab565b905060ff8111620001d4576001969095509350505050565b505b5060009485945092505050565b634e487b7160e01b600052604160045260246000fd5b60405161018081016001600160401b03811182821017156200021f576200021f620001e3565b60405290565b80516001600160a01b03811681146200023d57600080fd5b919050565b60005b838110156200025f57818101518382015260200162000245565b50506000910152565b600082601f8301126200027a57600080fd5b81516001600160401b0380821115620002975762000297620001e3565b604051601f8301601f19908116603f01168101908282118183101715620002c257620002c2620001e3565b81604052838152866020858801011115620002dc57600080fd5b620002ef84602083016020890162000242565b9695505050505050565b6000602082840312156200030c57600080fd5b81516001600160401b03808211156200032457600080fd5b9083019061018082860312156200033a57600080fd5b62000344620001f9565b6200034f8362000225565b81526200035f6020840162000225565b6020820152620003726040840162000225565b60408201526060830151828111156200038a57600080fd5b620003988782860162000268565b606083015250608083015182811115620003b157600080fd5b620003bf8782860162000268565b60808301525060a0838101519082015260c0808401519082015260e080840151908201526101008084015190820152610120808401519082015261014091506200040b82840162000225565b8282015261016091506200042182840162000225565b91810191909152949350505050565b600181811c908216806200044557607f821691505b6020821081036200046657634e487b7160e01b600052602260045260246000fd5b50919050565b601f821115620004bc576000816000526020600020601f850160051c81016020861015620004975750805b601f850160051c820191505b81811015620004b857828155600101620004a3565b5050505b505050565b81516001600160401b03811115620004dd57620004dd620001e3565b620004f581620004ee845462000430565b846200046c565b602080601f8311600181146200052d5760008415620005145750858301515b600019600386901b1c1916600185901b178555620004b8565b600085815260208120601f198616915b828110156200055e578886015182559484019460019091019084016200053d565b50858210156200057d5787850151600019600388901b60f8161c191681555b5050505050600190811b01905550565b60008251620005a181846020870162000242565b9190910192915050565b600060208284031215620005be57600080fd5b5051919050565b60805160a051611421620005f960003960006105780152600081816102e001528181610869015261095e01526114216000f3fe608060405234801561001057600080fd5b50600436106101fb5760003560e01c806370a082311161011a578063ba087652116100ad578063ce96cb771161007c578063ce96cb7714610418578063d905777e1461042b578063dd62ed3e1461043e578063ef8b30f714610405578063fa2f0ee91461047757600080fd5b8063ba087652146103e9578063c52619de146103fc578063c63d75b614610304578063c6e6f5921461040557600080fd5b806395d89b41116100e957806395d89b41146103a8578063a9059cbb146103b0578063b3d7f6b9146103c3578063b460af94146103d657600080fd5b806370a082311461033e5780637f05b8bf146103675780639013a06c1461037457806394bf804d1461039557600080fd5b8063313ce567116101925780634cdad506116101615780634cdad5061461022c57806364b8868c1461031957806368a08c63146103225780636e553f651461032b57600080fd5b8063313ce56714610299578063375b74c3146102b357806338d52e0f146102de578063402d267d1461030457600080fd5b80630a28a477116101ce5780630a28a4771461026257806312279b7c1461027557806318160ddd1461027e57806323b872dd1461028657600080fd5b806301e1d1141461020057806306fdde031461021757806307a2d13a1461022c578063095ea7b31461023f575b600080fd5b6006545b6040519081526020015b60405180910390f35b61021f610480565b60405161020e919061100d565b61020461023a366004611040565b610512565b61025261024d366004611075565b610525565b604051901515815260200161020e565b610204610270366004611040565b61053d565b61020460065481565b600254610204565b61025261029436600461109f565b61054a565b6102a1610570565b60405160ff909116815260200161020e565b6005546102c6906001600160a01b031681565b6040516001600160a01b03909116815260200161020e565b7f00000000000000000000000000000000000000000000000000000000000000006102c6565b6102046103123660046110db565b5060001990565b61020460095481565b61020460075481565b6102046103393660046110f6565b6105a1565b61020461034c3660046110db565b6001600160a01b031660009081526020819052604090205490565b600b546102529060ff1681565b610393610382366004611130565b600b805460ff191682151517905550565b005b6102046103a33660046110f6565b6105d8565b61021f6105f6565b6102526103be366004611075565b610605565b6102046103d1366004611040565b610613565b6102046103e436600461114d565b610620565b6102046103f736600461114d565b610678565b610204600a5481565b610204610413366004611040565b6106c7565b6102046104263660046110db565b6106d4565b6102046104393660046110db565b6106f8565b61020461044c366004611189565b6001600160a01b03918216600090815260016020908152604080832093909416825291909152205490565b61020460085481565b60606003805461048f906111b3565b80601f01602080910402602001604051908101604052809291908181526020018280546104bb906111b3565b80156105085780601f106104dd57610100808354040283529160200191610508565b820191906000526020600020905b8154815290600101906020018083116104eb57829003601f168201915b5050505050905090565b600061051f826000610716565b92915050565b600033610533818585610751565b5060019392505050565b600061051f826001610763565b60003361055885828561078e565b6105638585856107f9565b60019150505b9392505050565b600061059c817f0000000000000000000000000000000000000000000000000000000000000000611203565b905090565b60006000196105b4565b60405180910390fd5b60006105bf856106c7565b90506105cd33858784610858565b949350505050565b50565b600060001960006105e885610613565b90506105cd33858388610858565b60606004805461048f906111b3565b6000336105338185856107f9565b600061051f826001610716565b60008061062c836106d4565b90508085111561065557828582604051633fa733bb60e21b81526004016105ab9392919061121c565b60006106608661053d565b905061066f338686898561091e565b95945050505050565b600080610684836106f8565b9050808511156106ad57828582604051632e52afbb60e21b81526004016105ab9392919061121c565b60006106b886610512565b905061066f338686848a61091e565b600061051f826000610763565b6001600160a01b03811660009081526020819052604081205461051f906000610716565b6001600160a01b03811660009081526020819052604081205461051f565b600061056961072460065490565b61072f90600161123d565b61073b6000600a611334565b600254610748919061123d565b859190856109f4565b61075e8383836001610a43565b505050565b600061056961077382600a611334565b600254610780919061123d565b60065461074890600161123d565b6001600160a01b0383811660009081526001602090815260408083209386168352929052205460001981146107f357818110156107e457828183604051637dc7a0d960e11b81526004016105ab9392919061121c565b6107f384848484036000610a43565b50505050565b6001600160a01b03831661082357604051634b637e8f60e11b8152600060048201526024016105ab565b6001600160a01b03821661084d5760405163ec442f0560e01b8152600060048201526024016105ab565b61075e838383610b18565b83838383610864610c2f565b61089c7f00000000000000000000000000000000000000000000000000000000000000006005548a906001600160a01b031689610c3f565b85600660008282546108ae919061123d565b909155506108be90508786610ca6565b866001600160a01b0316886001600160a01b03167fdcbc1c05240f31ff3ad067ef1ee35ce4997762752e3a095284754544f4c709d7888860405161090c929190918252602082015260400190565b60405180910390a35050505050505050565b848484848461092b610ce0565b876001600160a01b03168a6001600160a01b03161461094f5761094f888b8861078e565b6109598887610cee565b6109847f00000000000000000000000000000000000000000000000000000000000000008a89610d24565b86600660008282546109969190611343565b909155505060408051888152602081018890526001600160a01b03808b16928c821692918e16917ffbde797d201c681b91056529119e0b02407c7bb96a4a2c75c01fc9667232c8db910160405180910390a450505050505050505050565b600080610a02868686610d55565b9050610a0d83610e19565b8015610a29575060008480610a2457610a24611356565b868809115b1561066f57610a3960018261123d565b9695505050505050565b6001600160a01b038416610a6d5760405163e602df0560e01b8152600060048201526024016105ab565b6001600160a01b038316610a9757604051634a1406b160e11b8152600060048201526024016105ab565b6001600160a01b03808516600090815260016020908152604080832093871683529290522082905580156107f357826001600160a01b0316846001600160a01b03167f8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b92584604051610b0a91815260200190565b60405180910390a350505050565b6001600160a01b038316610b43578060026000828254610b38919061123d565b90915550610ba29050565b6001600160a01b03831660009081526020819052604090205481811015610b835783818360405163391434e360e21b81526004016105ab9392919061121c565b6001600160a01b03841660009081526020819052604090209082900390555b6001600160a01b038216610bbe57600280548290039055610bdd565b6001600160a01b03821660009081526020819052604090208054820190555b816001600160a01b0316836001600160a01b03167fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef83604051610c2291815260200190565b60405180910390a3505050565b610c3d600754600854610e46565b565b6040516001600160a01b0384811660248301528381166044830152606482018390526107f39186918216906323b872dd906084015b604051602081830303815290604052915060e01b6020820180516001600160e01b038381831617835250505050610e8e565b6001600160a01b038216610cd05760405163ec442f0560e01b8152600060048201526024016105ab565b610cdc60008383610b18565b5050565b610c3d600954600a54610e46565b6001600160a01b038216610d1857604051634b637e8f60e11b8152600060048201526024016105ab565b610cdc82600083610b18565b6040516001600160a01b0383811660248301526044820183905261075e91859182169063a9059cbb90606401610c74565b6000838302816000198587098281108382030391505080600003610d8c57838281610d8257610d82611356565b0492505050610569565b808411610dac5760405163227bc15360e01b815260040160405180910390fd5b6000848688096000868103871696879004966002600389028118808a02820302808a02820302808a02820302808a02820302808a02820302808a02909103029181900381900460010186841190950394909402919094039290920491909117919091029150509392505050565b60006002826003811115610e2f57610e2f61136c565b610e399190611382565b60ff166001149050919050565b600b5460ff168015610e60575081421080610e6057508042115b15610cdc576040516392b4e60760e01b815260048101839052602481018290524260448201526064016105ab565b6000610ea36001600160a01b03841683610ef1565b90508051600014158015610ec8575080806020019051810190610ec691906113b2565b155b1561075e57604051635274afe760e01b81526001600160a01b03841660048201526024016105ab565b60606105698383600084600080856001600160a01b03168486604051610f1791906113cf565b60006040518083038185875af1925050503d8060008114610f54576040519150601f19603f3d011682016040523d82523d6000602084013e610f59565b606091505b5091509150610a39868383606082610f7957610f7482610fc0565b610569565b8151158015610f9057506001600160a01b0384163b155b15610fb957604051639996b31560e01b81526001600160a01b03851660048201526024016105ab565b5080610569565b805115610fd05780518082602001fd5b604051630a12f52160e11b815260040160405180910390fd5b60005b83811015611004578181015183820152602001610fec565b50506000910152565b602081526000825180602084015261102c816040850160208701610fe9565b601f01601f19169190910160400192915050565b60006020828403121561105257600080fd5b5035919050565b80356001600160a01b038116811461107057600080fd5b919050565b6000806040838503121561108857600080fd5b61109183611059565b946020939093013593505050565b6000806000606084860312156110b457600080fd5b6110bd84611059565b92506110cb60208501611059565b9150604084013590509250925092565b6000602082840312156110ed57600080fd5b61056982611059565b6000806040838503121561110957600080fd5b8235915061111960208401611059565b90509250929050565b80151581146105d557600080fd5b60006020828403121561114257600080fd5b813561056981611122565b60008060006060848603121561116257600080fd5b8335925061117260208501611059565b915061118060408501611059565b90509250925092565b6000806040838503121561119c57600080fd5b6111a583611059565b915061111960208401611059565b600181811c908216806111c757607f821691505b6020821081036111e757634e487b7160e01b600052602260045260246000fd5b50919050565b634e487b7160e01b600052601160045260246000fd5b60ff818116838216019081111561051f5761051f6111ed565b6001600160a01b039390931683526020830191909152604082015260600190565b8082018082111561051f5761051f6111ed565b600181815b8085111561128b578160001904821115611271576112716111ed565b8085161561127e57918102915b93841c9390800290611255565b509250929050565b6000826112a25750600161051f565b816112af5750600061051f565b81600181146112c557600281146112cf576112eb565b600191505061051f565b60ff8411156112e0576112e06111ed565b50506001821b61051f565b5060208310610133831016604e8410600b841016171561130e575081810a61051f565b6113188383611250565b806000190482111561132c5761132c6111ed565b029392505050565b600061056960ff841683611293565b8181038181111561051f5761051f6111ed565b634e487b7160e01b600052601260045260246000fd5b634e487b7160e01b600052602160045260246000fd5b600060ff8316806113a357634e487b7160e01b600052601260045260246000fd5b8060ff84160691505092915050565b6000602082840312156113c457600080fd5b815161056981611122565b600082516113e1818460208701610fe9565b919091019291505056fea26469706673582212207be020f62bca5c9f14f7b65ff0b51d18b3c9396200c8e6c9604aa2724fdc6e7e64736f6c63430008160033";

type WindowVaultMockConstructorParams =
  | [signer?: Signer]
  | ConstructorParameters<typeof ContractFactory>;

const isSuperArgs = (
  xs: WindowVaultMockConstructorParams
): xs is ConstructorParameters<typeof ContractFactory> => xs.length > 1;

export class WindowVaultMock__factory extends ContractFactory {
  constructor(...args: WindowVaultMockConstructorParams) {
    if (isSuperArgs(args)) {
      super(...args);
    } else {
      super(_abi, _bytecode, args[0]);
    }
  }

  override deploy(
    params: ICredbull.VaultParamsStruct,
    overrides?: Overrides & { from?: string }
  ): Promise<WindowVaultMock> {
    return super.deploy(params, overrides || {}) as Promise<WindowVaultMock>;
  }
  override getDeployTransaction(
    params: ICredbull.VaultParamsStruct,
    overrides?: Overrides & { from?: string }
  ): TransactionRequest {
    return super.getDeployTransaction(params, overrides || {});
  }
  override attach(address: string): WindowVaultMock {
    return super.attach(address) as WindowVaultMock;
  }
  override connect(signer: Signer): WindowVaultMock__factory {
    return super.connect(signer) as WindowVaultMock__factory;
  }

  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): WindowVaultMockInterface {
    return new utils.Interface(_abi) as WindowVaultMockInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): WindowVaultMock {
    return new Contract(address, _abi, signerOrProvider) as WindowVaultMock;
  }
}
