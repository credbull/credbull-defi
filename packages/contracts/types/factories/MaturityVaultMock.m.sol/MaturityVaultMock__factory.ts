/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import { Signer, utils, Contract, ContractFactory, Overrides } from "ethers";
import type { Provider, TransactionRequest } from "@ethersproject/providers";
import type {
  MaturityVaultMock,
  MaturityVaultMockInterface,
  ICredbull,
} from "../../MaturityVaultMock.m.sol/MaturityVaultMock";

const _abi = [
  {
    type: "constructor",
    inputs: [
      {
        name: "params",
        type: "tuple",
        internalType: "struct ICredbull.VaultParams",
        components: [
          {
            name: "owner",
            type: "address",
            internalType: "address",
          },
          {
            name: "operator",
            type: "address",
            internalType: "address",
          },
          {
            name: "asset",
            type: "address",
            internalType: "contract IERC20",
          },
          {
            name: "token",
            type: "address",
            internalType: "contract IERC20",
          },
          {
            name: "shareName",
            type: "string",
            internalType: "string",
          },
          {
            name: "shareSymbol",
            type: "string",
            internalType: "string",
          },
          {
            name: "promisedYield",
            type: "uint256",
            internalType: "uint256",
          },
          {
            name: "depositOpensAt",
            type: "uint256",
            internalType: "uint256",
          },
          {
            name: "depositClosesAt",
            type: "uint256",
            internalType: "uint256",
          },
          {
            name: "redemptionOpensAt",
            type: "uint256",
            internalType: "uint256",
          },
          {
            name: "redemptionClosesAt",
            type: "uint256",
            internalType: "uint256",
          },
          {
            name: "custodian",
            type: "address",
            internalType: "address",
          },
          {
            name: "kycProvider",
            type: "address",
            internalType: "address",
          },
        ],
      },
    ],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "allowance",
    inputs: [
      {
        name: "owner",
        type: "address",
        internalType: "address",
      },
      {
        name: "spender",
        type: "address",
        internalType: "address",
      },
    ],
    outputs: [
      {
        name: "",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "approve",
    inputs: [
      {
        name: "spender",
        type: "address",
        internalType: "address",
      },
      {
        name: "value",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    outputs: [
      {
        name: "",
        type: "bool",
        internalType: "bool",
      },
    ],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "asset",
    inputs: [],
    outputs: [
      {
        name: "",
        type: "address",
        internalType: "address",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "balanceOf",
    inputs: [
      {
        name: "account",
        type: "address",
        internalType: "address",
      },
    ],
    outputs: [
      {
        name: "",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "checkMaturity",
    inputs: [],
    outputs: [
      {
        name: "",
        type: "bool",
        internalType: "bool",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "convertToAssets",
    inputs: [
      {
        name: "shares",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    outputs: [
      {
        name: "",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "convertToShares",
    inputs: [
      {
        name: "assets",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    outputs: [
      {
        name: "",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "custodian",
    inputs: [],
    outputs: [
      {
        name: "",
        type: "address",
        internalType: "address",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "decimals",
    inputs: [],
    outputs: [
      {
        name: "",
        type: "uint8",
        internalType: "uint8",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "deposit",
    inputs: [
      {
        name: "assets",
        type: "uint256",
        internalType: "uint256",
      },
      {
        name: "receiver",
        type: "address",
        internalType: "address",
      },
    ],
    outputs: [
      {
        name: "",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "expectedAssetsOnMaturity",
    inputs: [],
    outputs: [
      {
        name: "",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "isMatured",
    inputs: [],
    outputs: [
      {
        name: "",
        type: "bool",
        internalType: "bool",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "mature",
    inputs: [],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "maxDeposit",
    inputs: [
      {
        name: "",
        type: "address",
        internalType: "address",
      },
    ],
    outputs: [
      {
        name: "",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "maxMint",
    inputs: [
      {
        name: "",
        type: "address",
        internalType: "address",
      },
    ],
    outputs: [
      {
        name: "",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "maxRedeem",
    inputs: [
      {
        name: "owner",
        type: "address",
        internalType: "address",
      },
    ],
    outputs: [
      {
        name: "",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "maxWithdraw",
    inputs: [
      {
        name: "owner",
        type: "address",
        internalType: "address",
      },
    ],
    outputs: [
      {
        name: "",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "mint",
    inputs: [
      {
        name: "shares",
        type: "uint256",
        internalType: "uint256",
      },
      {
        name: "receiver",
        type: "address",
        internalType: "address",
      },
    ],
    outputs: [
      {
        name: "",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "name",
    inputs: [],
    outputs: [
      {
        name: "",
        type: "string",
        internalType: "string",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "previewDeposit",
    inputs: [
      {
        name: "assets",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    outputs: [
      {
        name: "",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "previewMint",
    inputs: [
      {
        name: "shares",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    outputs: [
      {
        name: "",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "previewRedeem",
    inputs: [
      {
        name: "shares",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    outputs: [
      {
        name: "",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "previewWithdraw",
    inputs: [
      {
        name: "assets",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    outputs: [
      {
        name: "",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "redeem",
    inputs: [
      {
        name: "shares",
        type: "uint256",
        internalType: "uint256",
      },
      {
        name: "receiver",
        type: "address",
        internalType: "address",
      },
      {
        name: "owner",
        type: "address",
        internalType: "address",
      },
    ],
    outputs: [
      {
        name: "",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "symbol",
    inputs: [],
    outputs: [
      {
        name: "",
        type: "string",
        internalType: "string",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "toogleMaturityCheck",
    inputs: [
      {
        name: "status",
        type: "bool",
        internalType: "bool",
      },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "totalAssetDeposited",
    inputs: [],
    outputs: [
      {
        name: "",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "totalAssets",
    inputs: [],
    outputs: [
      {
        name: "",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "totalSupply",
    inputs: [],
    outputs: [
      {
        name: "",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "transfer",
    inputs: [
      {
        name: "to",
        type: "address",
        internalType: "address",
      },
      {
        name: "value",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    outputs: [
      {
        name: "",
        type: "bool",
        internalType: "bool",
      },
    ],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "transferFrom",
    inputs: [
      {
        name: "from",
        type: "address",
        internalType: "address",
      },
      {
        name: "to",
        type: "address",
        internalType: "address",
      },
      {
        name: "value",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    outputs: [
      {
        name: "",
        type: "bool",
        internalType: "bool",
      },
    ],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "withdraw",
    inputs: [
      {
        name: "assets",
        type: "uint256",
        internalType: "uint256",
      },
      {
        name: "receiver",
        type: "address",
        internalType: "address",
      },
      {
        name: "owner",
        type: "address",
        internalType: "address",
      },
    ],
    outputs: [
      {
        name: "",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    stateMutability: "nonpayable",
  },
  {
    type: "event",
    name: "Approval",
    inputs: [
      {
        name: "owner",
        type: "address",
        indexed: true,
        internalType: "address",
      },
      {
        name: "spender",
        type: "address",
        indexed: true,
        internalType: "address",
      },
      {
        name: "value",
        type: "uint256",
        indexed: false,
        internalType: "uint256",
      },
    ],
    anonymous: false,
  },
  {
    type: "event",
    name: "Deposit",
    inputs: [
      {
        name: "sender",
        type: "address",
        indexed: true,
        internalType: "address",
      },
      {
        name: "owner",
        type: "address",
        indexed: true,
        internalType: "address",
      },
      {
        name: "assets",
        type: "uint256",
        indexed: false,
        internalType: "uint256",
      },
      {
        name: "shares",
        type: "uint256",
        indexed: false,
        internalType: "uint256",
      },
    ],
    anonymous: false,
  },
  {
    type: "event",
    name: "Transfer",
    inputs: [
      {
        name: "from",
        type: "address",
        indexed: true,
        internalType: "address",
      },
      {
        name: "to",
        type: "address",
        indexed: true,
        internalType: "address",
      },
      {
        name: "value",
        type: "uint256",
        indexed: false,
        internalType: "uint256",
      },
    ],
    anonymous: false,
  },
  {
    type: "event",
    name: "Withdraw",
    inputs: [
      {
        name: "sender",
        type: "address",
        indexed: true,
        internalType: "address",
      },
      {
        name: "receiver",
        type: "address",
        indexed: true,
        internalType: "address",
      },
      {
        name: "owner",
        type: "address",
        indexed: true,
        internalType: "address",
      },
      {
        name: "assets",
        type: "uint256",
        indexed: false,
        internalType: "uint256",
      },
      {
        name: "shares",
        type: "uint256",
        indexed: false,
        internalType: "uint256",
      },
    ],
    anonymous: false,
  },
  {
    type: "error",
    name: "AddressEmptyCode",
    inputs: [
      {
        name: "target",
        type: "address",
        internalType: "address",
      },
    ],
  },
  {
    type: "error",
    name: "AddressInsufficientBalance",
    inputs: [
      {
        name: "account",
        type: "address",
        internalType: "address",
      },
    ],
  },
  {
    type: "error",
    name: "CredbullVault__NotEnoughBalanceToMature",
    inputs: [],
  },
  {
    type: "error",
    name: "CredbullVault__NotMatured",
    inputs: [],
  },
  {
    type: "error",
    name: "ERC20InsufficientAllowance",
    inputs: [
      {
        name: "spender",
        type: "address",
        internalType: "address",
      },
      {
        name: "allowance",
        type: "uint256",
        internalType: "uint256",
      },
      {
        name: "needed",
        type: "uint256",
        internalType: "uint256",
      },
    ],
  },
  {
    type: "error",
    name: "ERC20InsufficientBalance",
    inputs: [
      {
        name: "sender",
        type: "address",
        internalType: "address",
      },
      {
        name: "balance",
        type: "uint256",
        internalType: "uint256",
      },
      {
        name: "needed",
        type: "uint256",
        internalType: "uint256",
      },
    ],
  },
  {
    type: "error",
    name: "ERC20InvalidApprover",
    inputs: [
      {
        name: "approver",
        type: "address",
        internalType: "address",
      },
    ],
  },
  {
    type: "error",
    name: "ERC20InvalidReceiver",
    inputs: [
      {
        name: "receiver",
        type: "address",
        internalType: "address",
      },
    ],
  },
  {
    type: "error",
    name: "ERC20InvalidSender",
    inputs: [
      {
        name: "sender",
        type: "address",
        internalType: "address",
      },
    ],
  },
  {
    type: "error",
    name: "ERC20InvalidSpender",
    inputs: [
      {
        name: "spender",
        type: "address",
        internalType: "address",
      },
    ],
  },
  {
    type: "error",
    name: "ERC4626ExceededMaxDeposit",
    inputs: [
      {
        name: "receiver",
        type: "address",
        internalType: "address",
      },
      {
        name: "assets",
        type: "uint256",
        internalType: "uint256",
      },
      {
        name: "max",
        type: "uint256",
        internalType: "uint256",
      },
    ],
  },
  {
    type: "error",
    name: "ERC4626ExceededMaxMint",
    inputs: [
      {
        name: "receiver",
        type: "address",
        internalType: "address",
      },
      {
        name: "shares",
        type: "uint256",
        internalType: "uint256",
      },
      {
        name: "max",
        type: "uint256",
        internalType: "uint256",
      },
    ],
  },
  {
    type: "error",
    name: "ERC4626ExceededMaxRedeem",
    inputs: [
      {
        name: "owner",
        type: "address",
        internalType: "address",
      },
      {
        name: "shares",
        type: "uint256",
        internalType: "uint256",
      },
      {
        name: "max",
        type: "uint256",
        internalType: "uint256",
      },
    ],
  },
  {
    type: "error",
    name: "ERC4626ExceededMaxWithdraw",
    inputs: [
      {
        name: "owner",
        type: "address",
        internalType: "address",
      },
      {
        name: "assets",
        type: "uint256",
        internalType: "uint256",
      },
      {
        name: "max",
        type: "uint256",
        internalType: "uint256",
      },
    ],
  },
  {
    type: "error",
    name: "FailedInnerCall",
    inputs: [],
  },
  {
    type: "error",
    name: "MathOverflowedMulDiv",
    inputs: [],
  },
  {
    type: "error",
    name: "SafeERC20FailedOperation",
    inputs: [
      {
        name: "token",
        type: "address",
        internalType: "address",
      },
    ],
  },
] as const;

const _bytecode =
  "0x60c06040523480156200001157600080fd5b5060405162001b3f38038062001b3f8339810160408190526200003491620002dc565b8080806040015181608001518260a001518160039081620000569190620004b8565b506004620000658282620004b8565b5050506000806200007c83620000e160201b60201c565b91509150816200008e57601262000090565b805b60ff1660a05250506001600160a01b039081166080526101609091015160058054919092166001600160a01b03199091161790556007805461ff00191661010017905560c0015160085550620005bc565b60408051600481526024810182526020810180516001600160e01b031663313ce56760e01b17905290516000918291829182916001600160a01b038716916200012a9162000584565b600060405180830381855afa9150503d806000811462000167576040519150601f19603f3d011682016040523d82523d6000602084013e6200016c565b606091505b50915091508180156200018157506020815110155b15620001b9576000818060200190518101906200019f9190620005a2565b905060ff8111620001b7576001969095509350505050565b505b5060009485945092505050565b634e487b7160e01b600052604160045260246000fd5b6040516101a081016001600160401b0381118282101715620002025762000202620001c6565b60405290565b80516001600160a01b03811681146200022057600080fd5b919050565b60005b838110156200024257818101518382015260200162000228565b50506000910152565b600082601f8301126200025d57600080fd5b81516001600160401b03808211156200027a576200027a620001c6565b604051601f8301601f19908116603f01168101908282118183101715620002a557620002a5620001c6565b81604052838152866020858801011115620002bf57600080fd5b620002d284602083016020890162000225565b9695505050505050565b600060208284031215620002ef57600080fd5b81516001600160401b03808211156200030757600080fd5b908301906101a082860312156200031d57600080fd5b62000327620001dc565b620003328362000208565b8152620003426020840162000208565b6020820152620003556040840162000208565b6040820152620003686060840162000208565b60608201526080830151828111156200038057600080fd5b6200038e878286016200024b565b60808301525060a083015182811115620003a757600080fd5b620003b5878286016200024b565b60a08301525060c0838101519082015260e0808401519082015261010080840151908201526101208084015190820152610140808401519082015261016091506200040282840162000208565b8282015261018091506200041882840162000208565b91810191909152949350505050565b600181811c908216806200043c57607f821691505b6020821081036200045d57634e487b7160e01b600052602260045260246000fd5b50919050565b601f821115620004b3576000816000526020600020601f850160051c810160208610156200048e5750805b601f850160051c820191505b81811015620004af578281556001016200049a565b5050505b505050565b81516001600160401b03811115620004d457620004d4620001c6565b620004ec81620004e5845462000427565b8462000463565b602080601f8311600181146200052457600084156200050b5750858301515b600019600386901b1c1916600185901b178555620004af565b600085815260208120601f198616915b82811015620005555788860151825594840194600190910190840162000534565b5085821015620005745787850151600019600388901b60f8161c191681555b5050505050600190811b01905550565b600082516200059881846020870162000225565b9190910192915050565b600060208284031215620005b557600080fd5b5051919050565b60805160a051611548620005f760003960006105730152600081816102fb015281816108820152818161093b0152610b5e01526115486000f3fe608060405234801561001057600080fd5b50600436106101f05760003560e01c80637f2b6a0d1161010f578063ba087652116100a2578063d905777e11610071578063d905777e1461041a578063dc38710a1461042d578063dd62ed3e1461043f578063ef8b30f7146103f457600080fd5b8063ba087652146103e1578063c63d75b61461031f578063c6e6f592146103f4578063ce96cb771461040757600080fd5b80639ae3a658116100de5780639ae3a658146103a0578063a9059cbb146103a8578063b3d7f6b9146103bb578063b460af94146103ce57600080fd5b80637f2b6a0d1461037057806387b652071461037d57806394bf804d1461038557806395d89b411461039857600080fd5b806323b872dd11610187578063402d267d11610156578063402d267d1461031f5780634cdad506146102215780636e553f651461033457806370a082311461034757600080fd5b806323b872dd146102a1578063313ce567146102b4578063375b74c3146102ce57806338d52e0f146102f957600080fd5b80630a28a477116101c35780630a28a4771461025757806312279b7c1461026a57806318160ddd1461027357806322f3cc841461027b57600080fd5b806301e1d114146101f557806306fdde031461020c57806307a2d13a14610221578063095ea7b314610234575b600080fd5b6006545b6040519081526020015b60405180910390f35b610214610478565b604051610203919061111b565b6101f961022f36600461114e565b61050a565b610247610242366004611183565b61051d565b6040519015158152602001610203565b6101f961026536600461114e565b610535565b6101f960065481565b6002546101f9565b61029f6102893660046111bb565b6007805461ff0019166101008315150217905550565b005b6102476102af3660046111d8565b610545565b6102bc61056b565b60405160ff9091168152602001610203565b6005546102e1906001600160a01b031681565b6040516001600160a01b039091168152602001610203565b7f00000000000000000000000000000000000000000000000000000000000000006102e1565b6101f961032d366004611214565b5060001990565b6101f961034236600461122f565b61059c565b6101f9610355366004611214565b6001600160a01b031660009081526020819052604090205490565b6007546102479060ff1681565b61029f6105d0565b6101f961039336600461122f565b6105da565b6102146105f8565b6101f9610607565b6102476103b6366004611183565b610626565b6101f96103c936600461114e565b610634565b6101f96103dc36600461125b565b610641565b6101f96103ef36600461125b565b610699565b6101f961040236600461114e565b6106e8565b6101f9610415366004611214565b6106f5565b6101f9610428366004611214565b610719565b60075461024790610100900460ff1681565b6101f961044d366004611297565b6001600160a01b03918216600090815260016020908152604080832093909416825291909152205490565b606060038054610487906112c1565b80601f01602080910402602001604051908101604052809291908181526020018280546104b3906112c1565b80156105005780601f106104d557610100808354040283529160200191610500565b820191906000526020600020905b8154815290600101906020018083116104e357829003601f168201915b5050505050905090565b6000610517826000610737565b92915050565b60003361052b818585610772565b5060019392505050565b6000610517826001610784565b50565b6000336105538582856107af565b61055e85858561081a565b60019150505b9392505050565b6000610597817f0000000000000000000000000000000000000000000000000000000000000000611311565b905090565b60006000196105af565b60405180910390fd5b60006105ba856106e8565b90506105c833858784610879565b949350505050565b6105d8610937565b565b600060001960006105ea85610634565b90506105c833858388610879565b606060048054610487906112c1565b6000610597600854606461061b919061134b565b600654906064610a5a565b60003361052b81858561081a565b6000610517826001610737565b60008061064d836106f5565b90508085111561067657828582604051633fa733bb60e21b81526004016105a69392919061132a565b600061068186610535565b90506106903386868985610b1e565b95945050505050565b6000806106a583610719565b9050808511156106ce57828582604051632e52afbb60e21b81526004016105a69392919061132a565b60006106d98661050a565b9050610690338686848a610b1e565b6000610517826000610784565b6001600160a01b038116600090815260208190526040812054610517906000610737565b6001600160a01b038116600090815260208190526040812054610517565b600061056461074560065490565b61075090600161134b565b61075c6000600a611442565b600254610769919061134b565b85919085610bf4565b61077f8383836001610c43565b505050565b600061056461079482600a611442565b6002546107a1919061134b565b60065461076990600161134b565b6001600160a01b038381166000908152600160209081526040808320938616835292905220546000198114610814578181101561080557828183604051637dc7a0d960e11b81526004016105a69392919061132a565b61081484848484036000610c43565b50505050565b6001600160a01b03831661084457604051634b637e8f60e11b8152600060048201526024016105a6565b6001600160a01b03821661086e5760405163ec442f0560e01b8152600060048201526024016105a6565b61077f838383610d18565b838383836108b57f00000000000000000000000000000000000000000000000000000000000000006005548a906001600160a01b031689610e2f565b85600660008282546108c7919061134b565b909155506108d790508786610e96565b866001600160a01b0316886001600160a01b03167fdcbc1c05240f31ff3ad067ef1ee35ce4997762752e3a095284754544f4c709d78888604051610925929190918252602082015260400190565b60405180910390a35050505050505050565b60007f00000000000000000000000000000000000000000000000000000000000000006040516370a0823160e01b81523060048201526001600160a01b0391909116906370a0823190602401602060405180830381865afa1580156109a0573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906109c49190611451565b905080306001600160a01b0316639ae3a6586040518163ffffffff1660e01b8152600401602060405180830381865afa158015610a05573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190610a299190611451565b1115610a4857604051632177e25b60e21b815260040160405180910390fd5b6006556007805460ff19166001179055565b6000838302816000198587098281108382030391505080600003610a9157838281610a8757610a8761146a565b0492505050610564565b808411610ab15760405163227bc15360e01b815260040160405180910390fd5b6000848688096000868103871696879004966002600389028118808a02820302808a02820302808a02820302808a02820302808a02820302808a02909103029181900381900460010186841190950394909402919094039290920491909117919091029150509392505050565b8484848484610b2b610ed0565b876001600160a01b03168a6001600160a01b031614610b4f57610b4f888b886107af565b610b598887610f08565b610b847f00000000000000000000000000000000000000000000000000000000000000008a89610f3e565b8660066000828254610b969190611480565b909155505060408051888152602081018890526001600160a01b03808b16928c821692918e16917ffbde797d201c681b91056529119e0b02407c7bb96a4a2c75c01fc9667232c8db910160405180910390a450505050505050505050565b600080610c02868686610a5a565b9050610c0d83610f6f565b8015610c29575060008480610c2457610c2461146a565b868809115b1561069057610c3960018261134b565b9695505050505050565b6001600160a01b038416610c6d5760405163e602df0560e01b8152600060048201526024016105a6565b6001600160a01b038316610c9757604051634a1406b160e11b8152600060048201526024016105a6565b6001600160a01b038085166000908152600160209081526040808320938716835292905220829055801561081457826001600160a01b0316846001600160a01b03167f8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b92584604051610d0a91815260200190565b60405180910390a350505050565b6001600160a01b038316610d43578060026000828254610d38919061134b565b90915550610da29050565b6001600160a01b03831660009081526020819052604090205481811015610d835783818360405163391434e360e21b81526004016105a69392919061132a565b6001600160a01b03841660009081526020819052604090209082900390555b6001600160a01b038216610dbe57600280548290039055610ddd565b6001600160a01b03821660009081526020819052604090208054820190555b816001600160a01b0316836001600160a01b03167fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef83604051610e2291815260200190565b60405180910390a3505050565b6040516001600160a01b0384811660248301528381166044830152606482018390526108149186918216906323b872dd906084015b604051602081830303815290604052915060e01b6020820180516001600160e01b038381831617835250505050610f9c565b6001600160a01b038216610ec05760405163ec442f0560e01b8152600060048201526024016105a6565b610ecc60008383610d18565b5050565b600754610100900460ff168015610eea575060075460ff16155b156105d857604051631cde10c760e31b815260040160405180910390fd5b6001600160a01b038216610f3257604051634b637e8f60e11b8152600060048201526024016105a6565b610ecc82600083610d18565b6040516001600160a01b0383811660248301526044820183905261077f91859182169063a9059cbb90606401610e64565b60006002826003811115610f8557610f85611493565b610f8f91906114a9565b60ff166001149050919050565b6000610fb16001600160a01b03841683610fff565b90508051600014158015610fd6575080806020019051810190610fd491906114d9565b155b1561077f57604051635274afe760e01b81526001600160a01b03841660048201526024016105a6565b60606105648383600084600080856001600160a01b0316848660405161102591906114f6565b60006040518083038185875af1925050503d8060008114611062576040519150601f19603f3d011682016040523d82523d6000602084013e611067565b606091505b5091509150610c3986838360608261108757611082826110ce565b610564565b815115801561109e57506001600160a01b0384163b155b156110c757604051639996b31560e01b81526001600160a01b03851660048201526024016105a6565b5080610564565b8051156110de5780518082602001fd5b604051630a12f52160e11b815260040160405180910390fd5b60005b838110156111125781810151838201526020016110fa565b50506000910152565b602081526000825180602084015261113a8160408501602087016110f7565b601f01601f19169190910160400192915050565b60006020828403121561116057600080fd5b5035919050565b80356001600160a01b038116811461117e57600080fd5b919050565b6000806040838503121561119657600080fd5b61119f83611167565b946020939093013593505050565b801515811461054257600080fd5b6000602082840312156111cd57600080fd5b8135610564816111ad565b6000806000606084860312156111ed57600080fd5b6111f684611167565b925061120460208501611167565b9150604084013590509250925092565b60006020828403121561122657600080fd5b61056482611167565b6000806040838503121561124257600080fd5b8235915061125260208401611167565b90509250929050565b60008060006060848603121561127057600080fd5b8335925061128060208501611167565b915061128e60408501611167565b90509250925092565b600080604083850312156112aa57600080fd5b6112b383611167565b915061125260208401611167565b600181811c908216806112d557607f821691505b6020821081036112f557634e487b7160e01b600052602260045260246000fd5b50919050565b634e487b7160e01b600052601160045260246000fd5b60ff8181168382160190811115610517576105176112fb565b6001600160a01b039390931683526020830191909152604082015260600190565b80820180821115610517576105176112fb565b600181815b8085111561139957816000190482111561137f5761137f6112fb565b8085161561138c57918102915b93841c9390800290611363565b509250929050565b6000826113b057506001610517565b816113bd57506000610517565b81600181146113d357600281146113dd576113f9565b6001915050610517565b60ff8411156113ee576113ee6112fb565b50506001821b610517565b5060208310610133831016604e8410600b841016171561141c575081810a610517565b611426838361135e565b806000190482111561143a5761143a6112fb565b029392505050565b600061056460ff8416836113a1565b60006020828403121561146357600080fd5b5051919050565b634e487b7160e01b600052601260045260246000fd5b81810381811115610517576105176112fb565b634e487b7160e01b600052602160045260246000fd5b600060ff8316806114ca57634e487b7160e01b600052601260045260246000fd5b8060ff84160691505092915050565b6000602082840312156114eb57600080fd5b8151610564816111ad565b600082516115088184602087016110f7565b919091019291505056fea2646970667358221220711be4f079a007adffe4ba79d3f090753dfc9568204b9030733c24d5576ada9a64736f6c63430008170033";

type MaturityVaultMockConstructorParams =
  | [signer?: Signer]
  | ConstructorParameters<typeof ContractFactory>;

const isSuperArgs = (
  xs: MaturityVaultMockConstructorParams
): xs is ConstructorParameters<typeof ContractFactory> => xs.length > 1;

export class MaturityVaultMock__factory extends ContractFactory {
  constructor(...args: MaturityVaultMockConstructorParams) {
    if (isSuperArgs(args)) {
      super(...args);
    } else {
      super(_abi, _bytecode, args[0]);
    }
  }

  override deploy(
    params: ICredbull.VaultParamsStruct,
    overrides?: Overrides & { from?: string }
  ): Promise<MaturityVaultMock> {
    return super.deploy(params, overrides || {}) as Promise<MaturityVaultMock>;
  }
  override getDeployTransaction(
    params: ICredbull.VaultParamsStruct,
    overrides?: Overrides & { from?: string }
  ): TransactionRequest {
    return super.getDeployTransaction(params, overrides || {});
  }
  override attach(address: string): MaturityVaultMock {
    return super.attach(address) as MaturityVaultMock;
  }
  override connect(signer: Signer): MaturityVaultMock__factory {
    return super.connect(signer) as MaturityVaultMock__factory;
  }

  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): MaturityVaultMockInterface {
    return new utils.Interface(_abi) as MaturityVaultMockInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): MaturityVaultMock {
    return new Contract(address, _abi, signerOrProvider) as MaturityVaultMock;
  }
}
