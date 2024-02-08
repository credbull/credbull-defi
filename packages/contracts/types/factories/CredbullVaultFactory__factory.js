"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.CredbullVaultFactory__factory = void 0;
/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
const ethers_1 = require("ethers");
const _abi = [
    {
        type: "constructor",
        inputs: [
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
        ],
        stateMutability: "nonpayable",
    },
    {
        type: "function",
        name: "DEFAULT_ADMIN_ROLE",
        inputs: [],
        outputs: [
            {
                name: "",
                type: "bytes32",
                internalType: "bytes32",
            },
        ],
        stateMutability: "view",
    },
    {
        type: "function",
        name: "OPERATOR_ROLE",
        inputs: [],
        outputs: [
            {
                name: "",
                type: "bytes32",
                internalType: "bytes32",
            },
        ],
        stateMutability: "view",
    },
    {
        type: "function",
        name: "createVault",
        inputs: [
            {
                name: "_params",
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
            {
                name: "_options",
                type: "string",
                internalType: "string",
            },
        ],
        outputs: [
            {
                name: "",
                type: "address",
                internalType: "address",
            },
        ],
        stateMutability: "nonpayable",
    },
    {
        type: "function",
        name: "getRoleAdmin",
        inputs: [
            {
                name: "role",
                type: "bytes32",
                internalType: "bytes32",
            },
        ],
        outputs: [
            {
                name: "",
                type: "bytes32",
                internalType: "bytes32",
            },
        ],
        stateMutability: "view",
    },
    {
        type: "function",
        name: "getTotalVaultCount",
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
        name: "getVaultAtIndex",
        inputs: [
            {
                name: "_index",
                type: "uint256",
                internalType: "uint256",
            },
        ],
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
        name: "grantRole",
        inputs: [
            {
                name: "role",
                type: "bytes32",
                internalType: "bytes32",
            },
            {
                name: "account",
                type: "address",
                internalType: "address",
            },
        ],
        outputs: [],
        stateMutability: "nonpayable",
    },
    {
        type: "function",
        name: "hasRole",
        inputs: [
            {
                name: "role",
                type: "bytes32",
                internalType: "bytes32",
            },
            {
                name: "account",
                type: "address",
                internalType: "address",
            },
        ],
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
        name: "isVaultExist",
        inputs: [
            {
                name: "_vault",
                type: "address",
                internalType: "address",
            },
        ],
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
        name: "renounceRole",
        inputs: [
            {
                name: "role",
                type: "bytes32",
                internalType: "bytes32",
            },
            {
                name: "callerConfirmation",
                type: "address",
                internalType: "address",
            },
        ],
        outputs: [],
        stateMutability: "nonpayable",
    },
    {
        type: "function",
        name: "revokeRole",
        inputs: [
            {
                name: "role",
                type: "bytes32",
                internalType: "bytes32",
            },
            {
                name: "account",
                type: "address",
                internalType: "address",
            },
        ],
        outputs: [],
        stateMutability: "nonpayable",
    },
    {
        type: "function",
        name: "supportsInterface",
        inputs: [
            {
                name: "interfaceId",
                type: "bytes4",
                internalType: "bytes4",
            },
        ],
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
        type: "event",
        name: "RoleAdminChanged",
        inputs: [
            {
                name: "role",
                type: "bytes32",
                indexed: true,
                internalType: "bytes32",
            },
            {
                name: "previousAdminRole",
                type: "bytes32",
                indexed: true,
                internalType: "bytes32",
            },
            {
                name: "newAdminRole",
                type: "bytes32",
                indexed: true,
                internalType: "bytes32",
            },
        ],
        anonymous: false,
    },
    {
        type: "event",
        name: "RoleGranted",
        inputs: [
            {
                name: "role",
                type: "bytes32",
                indexed: true,
                internalType: "bytes32",
            },
            {
                name: "account",
                type: "address",
                indexed: true,
                internalType: "address",
            },
            {
                name: "sender",
                type: "address",
                indexed: true,
                internalType: "address",
            },
        ],
        anonymous: false,
    },
    {
        type: "event",
        name: "RoleRevoked",
        inputs: [
            {
                name: "role",
                type: "bytes32",
                indexed: true,
                internalType: "bytes32",
            },
            {
                name: "account",
                type: "address",
                indexed: true,
                internalType: "address",
            },
            {
                name: "sender",
                type: "address",
                indexed: true,
                internalType: "address",
            },
        ],
        anonymous: false,
    },
    {
        type: "event",
        name: "VaultDeployed",
        inputs: [
            {
                name: "vault",
                type: "address",
                indexed: true,
                internalType: "address",
            },
            {
                name: "params",
                type: "tuple",
                indexed: false,
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
            {
                name: "options",
                type: "string",
                indexed: false,
                internalType: "string",
            },
        ],
        anonymous: false,
    },
    {
        type: "error",
        name: "AccessControlBadConfirmation",
        inputs: [],
    },
    {
        type: "error",
        name: "AccessControlUnauthorizedAccount",
        inputs: [
            {
                name: "account",
                type: "address",
                internalType: "address",
            },
            {
                name: "neededRole",
                type: "bytes32",
                internalType: "bytes32",
            },
        ],
    },
];
const _bytecode = "0x608060405234801561001057600080fd5b50604051612f8f380380612f8f83398101604081905261002f91610135565b61003a60008361006d565b506100657f97667070c54ef182b0f5858b034beac1b6f3089aa2d3188bb1e8929f4fa9b9298261006d565b505050610168565b6000828152602081815260408083206001600160a01b038516845290915281205460ff1661010f576000838152602081815260408083206001600160a01b03861684529091529020805460ff191660011790556100c73390565b6001600160a01b0316826001600160a01b0316847f2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d60405160405180910390a4506001610113565b5060005b92915050565b80516001600160a01b038116811461013057600080fd5b919050565b6000806040838503121561014857600080fd5b61015183610119565b915061015f60208401610119565b90509250929050565b612e18806101776000396000f3fe60806040523480156200001157600080fd5b5060043610620000c35760003560e01c80635a13d715116200007a5780635a13d71514620001a05780637354231e14620001b757806391d1485414620001c1578063a217fddf14620001d8578063d547741f14620001e1578063f5b541a614620001f857600080fd5b806301ffc9a714620000c85780630ce44e3a14620000f457806313a1f1661462000124578063248a9ca3146200013b5780632f2ff15d146200017057806336568abe1462000189575b600080fd5b620000df620000d936600462000646565b62000220565b60405190151581526020015b60405180910390f35b6200010b6200010536600462000672565b62000258565b6040516001600160a01b039091168152602001620000eb565b620000df62000135366004620006b4565b62000267565b620001616200014c36600462000672565b60009081526020819052604090206001015490565b604051908152602001620000eb565b6200018762000181366004620006d4565b62000276565b005b620001876200019a366004620006d4565b620002a5565b6200010b620001b13660046200082b565b620002e0565b62000161620003a9565b620000df620001d2366004620006d4565b620003bc565b62000161600081565b62000187620001f2366004620006d4565b620003e5565b620001617f97667070c54ef182b0f5858b034beac1b6f3089aa2d3188bb1e8929f4fa9b92981565b60006001600160e01b03198216637965db0b60e01b14806200025257506301ffc9a760e01b6001600160e01b03198316145b92915050565b6000620002526001836200040e565b60006200025260018362000423565b600082815260208190526040902060010154620002938162000446565b6200029f838362000455565b50505050565b6001600160a01b0381163314620002cf5760405163334bd91960e11b815260040160405180910390fd5b620002db8282620004ed565b505050565b60007f97667070c54ef182b0f5858b034beac1b6f3089aa2d3188bb1e8929f4fa9b9296200030e8162000446565b6000856040516200031f9062000638565b6200032b919062000af7565b604051809103906000f08015801562000348573d6000803e3d6000fd5b509050806001600160a01b03167fb562c5b8a63309d53026669d962fb221bb591ddca35e2e5a5a0f16731467c03a8787876040516200038a9392919062000b0c565b60405180910390a26200039f6001826200055c565b5095945050505050565b6000620003b7600162000573565b905090565b6000918252602082815260408084206001600160a01b0393909316845291905290205460ff1690565b600082815260208190526040902060010154620004028162000446565b6200029f8383620004ed565b60006200041c83836200057e565b9392505050565b6001600160a01b038116600090815260018301602052604081205415156200041c565b620004528133620005ab565b50565b6000620004638383620003bc565b620004e4576000838152602081815260408083206001600160a01b03861684529091529020805460ff191660011790556200049b3390565b6001600160a01b0316826001600160a01b0316847f2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d60405160405180910390a450600162000252565b50600062000252565b6000620004fb8383620003bc565b15620004e4576000838152602081815260408083206001600160a01b0386168085529252808320805460ff1916905551339286917ff6391f5c32d9c69d2a47ea670b442974b53935d1edc7fd64eb21e047a839171b9190a450600162000252565b60006200041c836001600160a01b038416620005ef565b600062000252825490565b600082600001828154811062000598576200059862000b54565b9060005260206000200154905092915050565b620005b78282620003bc565b620005eb5760405163e2517d3f60e01b81526001600160a01b03821660048201526024810183905260440160405180910390fd5b5050565b6000818152600183016020526040812054620004e45750815460018181018455600084815260208082209093018490558454848252828601909352604090209190915562000252565b6122788062000b6b83390190565b6000602082840312156200065957600080fd5b81356001600160e01b0319811681146200041c57600080fd5b6000602082840312156200068557600080fd5b5035919050565b6001600160a01b03811681146200045257600080fd5b8035620006af816200068c565b919050565b600060208284031215620006c757600080fd5b81356200041c816200068c565b60008060408385031215620006e857600080fd5b823591506020830135620006fc816200068c565b809150509250929050565b634e487b7160e01b600052604160045260246000fd5b6040516101a0810167ffffffffffffffff8111828210171562000744576200074462000707565b60405290565b600082601f8301126200075c57600080fd5b813567ffffffffffffffff808211156200077a576200077a62000707565b604051601f8301601f19908116603f01168101908282118183101715620007a557620007a562000707565b81604052838152866020858801011115620007bf57600080fd5b836020870160208301376000602085830101528094505050505092915050565b60008083601f840112620007f257600080fd5b50813567ffffffffffffffff8111156200080b57600080fd5b6020830191508360208285010111156200082457600080fd5b9250929050565b6000806000604084860312156200084157600080fd5b833567ffffffffffffffff808211156200085a57600080fd5b908501906101a082880312156200087057600080fd5b6200087a6200071d565b6200088583620006a2565b81526200089560208401620006a2565b6020820152620008a860408401620006a2565b6040820152620008bb60608401620006a2565b6060820152608083013582811115620008d357600080fd5b620008e1898286016200074a565b60808301525060a083013582811115620008fa57600080fd5b62000908898286016200074a565b60a08301525060c0838101359082015260e0808401359082015261010080840135908201526101208084013590820152610140808401359082015261016062000953818501620006a2565b9082015261018062000967848201620006a2565b90820152945060208601359150808211156200098257600080fd5b506200099186828701620007df565b9497909650939450505050565b6000815180845260005b81811015620009c657602081850181015186830182015201620009a8565b506000602082860101526020601f19601f83011685010191505092915050565b80516001600160a01b0316825260006101a0602083015162000a1360208601826001600160a01b03169052565b50604083015162000a2f60408601826001600160a01b03169052565b50606083015162000a4b60608601826001600160a01b03169052565b50608083015181608086015262000a65828601826200099e565b91505060a083015184820360a086015262000a8182826200099e565b91505060c083015160c085015260e083015160e08501526101008084015181860152506101208084015181860152506101408084015181860152506101608084015162000ad8828701826001600160a01b03169052565b5050610180928301516001600160a01b03169390920192909252919050565b6020815260006200041c6020830184620009e6565b60408152600062000b216040830186620009e6565b8281036020840152838152838560208301376000602085830101526020601f19601f860116820101915050949350505050565b634e487b7160e01b600052603260045260246000fdfe60c06040523480156200001157600080fd5b506040516200227838038062002278833981016040819052620000349162000437565b808060e001518161010001518261012001518361014001518461018001518580806040015181608001518260a00151816003908162000074919062000613565b50600462000083828262000613565b5050506000806200009a836200018960201b60201c565b9150915081620000ac576012620000ae565b805b60ff1660a05250506001600160a01b0390811660805261016090910151600580549183166001600160a01b03199092169190911790556007805461ff00191661010017905560c090910151600855600980546001600160a81b0319169290911691909117600160a01b179055600a93909355600b91909155600c55600d55600e805460ff19166001179055805162000149906000906200026e565b50620001807f97667070c54ef182b0f5858b034beac1b6f3089aa2d3188bb1e8929f4fa9b92982602001516200026e60201b60201c565b50505062000717565b60408051600481526024810182526020810180516001600160e01b031663313ce56760e01b17905290516000918291829182916001600160a01b03871691620001d291620006df565b600060405180830381855afa9150503d80600081146200020f576040519150601f19603f3d011682016040523d82523d6000602084013e62000214565b606091505b50915091508180156200022957506020815110155b156200026157600081806020019051810190620002479190620006fd565b905060ff81116200025f576001969095509350505050565b505b5060009485945092505050565b6000828152600f602090815260408083206001600160a01b038516845290915281205460ff1662000317576000838152600f602090815260408083206001600160a01b03861684529091529020805460ff19166001179055620002ce3390565b6001600160a01b0316826001600160a01b0316847f2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d60405160405180910390a45060016200031b565b5060005b92915050565b634e487b7160e01b600052604160045260246000fd5b6040516101a081016001600160401b03811182821017156200035d576200035d62000321565b60405290565b80516001600160a01b03811681146200037b57600080fd5b919050565b60005b838110156200039d57818101518382015260200162000383565b50506000910152565b600082601f830112620003b857600080fd5b81516001600160401b0380821115620003d557620003d562000321565b604051601f8301601f19908116603f0116810190828211818310171562000400576200040062000321565b816040528381528660208588010111156200041a57600080fd5b6200042d84602083016020890162000380565b9695505050505050565b6000602082840312156200044a57600080fd5b81516001600160401b03808211156200046257600080fd5b908301906101a082860312156200047857600080fd5b6200048262000337565b6200048d8362000363565b81526200049d6020840162000363565b6020820152620004b06040840162000363565b6040820152620004c36060840162000363565b6060820152608083015182811115620004db57600080fd5b620004e987828601620003a6565b60808301525060a0830151828111156200050257600080fd5b6200051087828601620003a6565b60a08301525060c0838101519082015260e0808401519082015261010080840151908201526101208084015190820152610140808401519082015261016091506200055d82840162000363565b8282015261018091506200057382840162000363565b91810191909152949350505050565b600181811c908216806200059757607f821691505b602082108103620005b857634e487b7160e01b600052602260045260246000fd5b50919050565b601f8211156200060e576000816000526020600020601f850160051c81016020861015620005e95750805b601f850160051c820191505b818110156200060a57828155600101620005f5565b5050505b505050565b81516001600160401b038111156200062f576200062f62000321565b620006478162000640845462000582565b84620005be565b602080601f8311600181146200067f5760008415620006665750858301515b600019600386901b1c1916600185901b1785556200060a565b600085815260208120601f198616915b82811015620006b0578886015182559484019460019091019084016200068f565b5085821015620006cf5787850151600019600388901b60f8161c191681555b5050505050600190811b01905550565b60008251620006f381846020870162000380565b9190910192915050565b6000602082840312156200071057600080fd5b5051919050565b60805160a051611b266200075260003960006107b501526000818161041201528181610cf101528181610daa0152610fd50152611b266000f3fe608060405234801561001057600080fd5b50600436106102bb5760003560e01c80637f2b6a0d11610182578063ba087652116100e9578063d905777e116100a2578063ef8b30f71161007c578063ef8b30f714610587578063f5b541a61461061e578063f85a609e14610645578063fa2f0ee91461065857600080fd5b8063d905777e146105c0578063dc38710a146105d3578063dd62ed3e146105e557600080fd5b8063ba0876521461056b578063c52619de1461057e578063c63d75b614610449578063c6e6f59214610587578063ce96cb771461059a578063d547741f146105ad57600080fd5b80639ae3a6581161013b5780639ae3a6581461050f578063a217fddf14610517578063a26c786f1461051f578063a9059cbb14610532578063b3d7f6b914610545578063b460af941461055857600080fd5b80637f2b6a0d146104b957806387b65207146104c65780639013a06c146104ce57806391d14854146104e157806394bf804d146104f457806395d89b411461050757600080fd5b8063313ce567116102265780634cdad506116101df5780634cdad5061461032357806364b8868c1461045e57806368a08c63146104675780636e553f651461047057806370a08231146104835780637f05b8bf146104ac57600080fd5b8063313ce567146103b857806336568abe146103d2578063375b74c3146103e557806338d52e0f146104105780633b8374a614610436578063402d267d1461044957600080fd5b80630a28a477116102785780630a28a4771461034957806312279b7c1461035c57806318160ddd1461036557806323b872dd1461036d578063248a9ca3146103805780632f2ff15d146103a357600080fd5b806301e1d114146102c057806301ffc9a7146102d757806306f2057a146102fa57806306fdde031461030e57806307a2d13a14610323578063095ea7b314610336575b600080fd5b6006545b6040519081526020015b60405180910390f35b6102ea6102e53660046116ab565b610661565b60405190151581526020016102ce565b6009546102ea90600160a01b900460ff1681565b610316610698565b6040516102ce91906116f9565b6102c461033136600461172c565b61072a565b6102ea610344366004611761565b610737565b6102c461035736600461172c565b61074f565b6102c460065481565b6002546102c4565b6102ea61037b36600461178b565b61075c565b6102c461038e36600461172c565b6000908152600f602052604090206001015490565b6103b66103b13660046117c7565b610782565b005b6103c06107ad565b60405160ff90911681526020016102ce565b6103b66103e03660046117c7565b6107de565b6005546103f8906001600160a01b031681565b6040516001600160a01b0390911681526020016102ce565b7f00000000000000000000000000000000000000000000000000000000000000006103f8565b6103b6610444366004611801565b610816565b6102c461045736600461181e565b5060001990565b6102c4600c5481565b6102c4600a5481565b6102c461047e3660046117c7565b61083c565b6102c461049136600461181e565b6001600160a01b031660009081526020819052604090205490565b600e546102ea9060ff1681565b6007546102ea9060ff1681565b6103b6610870565b6103b66104dc366004611801565b6108a5565b6102ea6104ef3660046117c7565b6108c2565b6102c46105023660046117c7565b6108ed565b61031661090b565b6102c461091a565b6102c4600081565b6009546103f8906001600160a01b031681565b6102ea610540366004611761565b610939565b6102c461055336600461172c565b610947565b6102c4610566366004611839565b610954565b6102c4610579366004611839565b6109ac565b6102c4600d5481565b6102c461059536600461172c565b6109fb565b6102c46105a836600461181e565b610a08565b6103b66105bb3660046117c7565b610a2c565b6102c46105ce36600461181e565b610a51565b6007546102ea90610100900460ff1681565b6102c46105f3366004611875565b6001600160a01b03918216600090815260016020908152604080832093909416825291909152205490565b6102c47f97667070c54ef182b0f5858b034beac1b6f3089aa2d3188bb1e8929f4fa9b92981565b6103b6610653366004611801565b610a6f565b6102c4600b5481565b60006001600160e01b03198216637965db0b60e01b148061069257506301ffc9a760e01b6001600160e01b03198316145b92915050565b6060600380546106a79061189f565b80601f01602080910402602001604051908101604052809291908181526020018280546106d39061189f565b80156107205780601f106106f557610100808354040283529160200191610720565b820191906000526020600020905b81548152906001019060200180831161070357829003601f168201915b5050505050905090565b6000610692826000610a95565b600033610745818585610ad0565b5060019392505050565b6000610692826001610add565b60003361076a858285610b08565b610775858585610b6d565b60019150505b9392505050565b6000828152600f602052604090206001015461079d81610bcc565b6107a78383610bd6565b50505050565b60006107d9817f00000000000000000000000000000000000000000000000000000000000000006118ef565b905090565b6001600160a01b03811633146108075760405163334bd91960e11b815260040160405180910390fd5b6108118282610c6a565b505050565b600061082181610bcc565b6007805461ff001916610100841515021790555050565b5050565b600060001961084f565b60405180910390fd5b600061085a856109fb565b905061086833858784610cd7565b949350505050565b7f97667070c54ef182b0f5858b034beac1b6f3089aa2d3188bb1e8929f4fa9b92961089a81610bcc565b6108a2610da6565b50565b60006108b081610bcc565b600e805460ff19168315151790555050565b6000918252600f602090815260408084206001600160a01b0393909316845291905290205460ff1690565b600060001960006108fd85610947565b905061086833858388610cd7565b6060600480546106a79061189f565b60006107d9600854606461092e9190611929565b600654906064610ec9565b600033610745818585610b6d565b6000610692826001610a95565b60008061096083610a08565b90508085111561098957828582604051633fa733bb60e21b815260040161084693929190611908565b60006109948661074f565b90506109a33386868985610f8d565b95945050505050565b6000806109b883610a51565b9050808511156109e157828582604051632e52afbb60e21b815260040161084693929190611908565b60006109ec8661072a565b90506109a3338686848a610f8d565b6000610692826000610add565b6001600160a01b038116600090815260208190526040812054610692906000610a95565b6000828152600f6020526040902060010154610a4781610bcc565b6107a78383610c6a565b6001600160a01b038116600090815260208190526040812054610692565b6000610a7a81610bcc565b6009805460ff60a01b1916600160a01b841515021790555050565b600061077b610aa360065490565b610aae906001611929565b610aba6000600a611a20565b600254610ac79190611929565b8591908561106b565b61081183838360016110ba565b600061077b610aed82600a611a20565b600254610afa9190611929565b600654610ac7906001611929565b6001600160a01b0383811660009081526001602090815260408083209386168352929052205460001981146107a75781811015610b5e57828183604051637dc7a0d960e11b815260040161084693929190611908565b6107a7848484840360006110ba565b6001600160a01b038316610b9757604051634b637e8f60e11b815260006004820152602401610846565b6001600160a01b038216610bc15760405163ec442f0560e01b815260006004820152602401610846565b61081183838361118f565b6108a281336112a6565b6000610be283836108c2565b610c62576000838152600f602090815260408083206001600160a01b03861684529091529020805460ff19166001179055610c1a3390565b6001600160a01b0316826001600160a01b0316847f2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d60405160405180910390a4506001610692565b506000610692565b6000610c7683836108c2565b15610c62576000838152600f602090815260408083206001600160a01b0386168085529252808320805460ff1916905551339286917ff6391f5c32d9c69d2a47ea670b442974b53935d1edc7fd64eb21e047a839171b9190a4506001610692565b83838383610ce4836112df565b610cec611381565b610d247f00000000000000000000000000000000000000000000000000000000000000006005548a906001600160a01b031689611391565b8560066000828254610d369190611929565b90915550610d46905087866113f8565b866001600160a01b0316886001600160a01b03167fdcbc1c05240f31ff3ad067ef1ee35ce4997762752e3a095284754544f4c709d78888604051610d94929190918252602082015260400190565b60405180910390a35050505050505050565b60007f00000000000000000000000000000000000000000000000000000000000000006040516370a0823160e01b81523060048201526001600160a01b0391909116906370a0823190602401602060405180830381865afa158015610e0f573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190610e339190611a2f565b905080306001600160a01b0316639ae3a6586040518163ffffffff1660e01b8152600401602060405180830381865afa158015610e74573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190610e989190611a2f565b1115610eb757604051632177e25b60e21b815260040160405180910390fd5b6006556007805460ff19166001179055565b6000838302816000198587098281108382030391505080600003610f0057838281610ef657610ef6611a48565b049250505061077b565b808411610f205760405163227bc15360e01b815260040160405180910390fd5b6000848688096000868103871696879004966002600389028118808a02820302808a02820302808a02820302808a02820302808a02820302808a02909103029181900381900460010186841190950394909402919094039290920491909117919091029150509392505050565b8484848484610f9a61142e565b610fa261143c565b876001600160a01b03168a6001600160a01b031614610fc657610fc6888b88610b08565b610fd08887611474565b610ffb7f00000000000000000000000000000000000000000000000000000000000000008a896114aa565b866006600082825461100d9190611a5e565b909155505060408051888152602081018890526001600160a01b03808b16928c821692918e16917ffbde797d201c681b91056529119e0b02407c7bb96a4a2c75c01fc9667232c8db910160405180910390a450505050505050505050565b600080611079868686610ec9565b9050611084836114db565b80156110a057506000848061109b5761109b611a48565b868809115b156109a3576110b0600182611929565b9695505050505050565b6001600160a01b0384166110e45760405163e602df0560e01b815260006004820152602401610846565b6001600160a01b03831661110e57604051634a1406b160e11b815260006004820152602401610846565b6001600160a01b03808516600090815260016020908152604080832093871683529290522082905580156107a757826001600160a01b0316846001600160a01b03167f8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b9258460405161118191815260200190565b60405180910390a350505050565b6001600160a01b0383166111ba5780600260008282546111af9190611929565b909155506112199050565b6001600160a01b038316600090815260208190526040902054818110156111fa5783818360405163391434e360e21b815260040161084693929190611908565b6001600160a01b03841660009081526020819052604090209082900390555b6001600160a01b03821661123557600280548290039055611254565b6001600160a01b03821660009081526020819052604090208054820190555b816001600160a01b0316836001600160a01b03167fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef8360405161129991815260200190565b60405180910390a3505050565b6112b082826108c2565b6108385760405163e2517d3f60e01b81526001600160a01b038216600482015260248101839052604401610846565b600954600160a01b900460ff168015611363575060095460405163645b8b1b60e01b81526001600160a01b0383811660048301529091169063645b8b1b90602401602060405180830381865afa15801561133d573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906113619190611a71565b155b156108a257604051636ecc5bb160e11b815260040160405180910390fd5b61138f600a54600b54611508565b565b6040516001600160a01b0384811660248301528381166044830152606482018390526107a79186918216906323b872dd906084015b604051602081830303815290604052915060e01b6020820180516001600160e01b038381831617835250505050611550565b6001600160a01b0382166114225760405163ec442f0560e01b815260006004820152602401610846565b6108386000838361118f565b61138f600c54600d54611508565b600754610100900460ff168015611456575060075460ff16155b1561138f57604051631cde10c760e31b815260040160405180910390fd5b6001600160a01b03821661149e57604051634b637e8f60e11b815260006004820152602401610846565b6108388260008361118f565b6040516001600160a01b0383811660248301526044820183905261081191859182169063a9059cbb906064016113c6565b600060028260038111156114f1576114f1611a8e565b6114fb9190611aa4565b60ff166001149050919050565b600e5460ff16801561152257508142108061152257508042115b15610838576040516392b4e60760e01b81526004810183905260248101829052426044820152606401610846565b60006115656001600160a01b038416836115b3565b9050805160001415801561158a5750808060200190518101906115889190611a71565b155b1561081157604051635274afe760e01b81526001600160a01b0384166004820152602401610846565b606061077b8383600084600080856001600160a01b031684866040516115d99190611ad4565b60006040518083038185875af1925050503d8060008114611616576040519150601f19603f3d011682016040523d82523d6000602084013e61161b565b606091505b50915091506110b086838360608261163b5761163682611682565b61077b565b815115801561165257506001600160a01b0384163b155b1561167b57604051639996b31560e01b81526001600160a01b0385166004820152602401610846565b508061077b565b8051156116925780518082602001fd5b604051630a12f52160e11b815260040160405180910390fd5b6000602082840312156116bd57600080fd5b81356001600160e01b03198116811461077b57600080fd5b60005b838110156116f05781810151838201526020016116d8565b50506000910152565b60208152600082518060208401526117188160408501602087016116d5565b601f01601f19169190910160400192915050565b60006020828403121561173e57600080fd5b5035919050565b80356001600160a01b038116811461175c57600080fd5b919050565b6000806040838503121561177457600080fd5b61177d83611745565b946020939093013593505050565b6000806000606084860312156117a057600080fd5b6117a984611745565b92506117b760208501611745565b9150604084013590509250925092565b600080604083850312156117da57600080fd5b823591506117ea60208401611745565b90509250929050565b80151581146108a257600080fd5b60006020828403121561181357600080fd5b813561077b816117f3565b60006020828403121561183057600080fd5b61077b82611745565b60008060006060848603121561184e57600080fd5b8335925061185e60208501611745565b915061186c60408501611745565b90509250925092565b6000806040838503121561188857600080fd5b61189183611745565b91506117ea60208401611745565b600181811c908216806118b357607f821691505b6020821081036118d357634e487b7160e01b600052602260045260246000fd5b50919050565b634e487b7160e01b600052601160045260246000fd5b60ff8181168382160190811115610692576106926118d9565b6001600160a01b039390931683526020830191909152604082015260600190565b80820180821115610692576106926118d9565b600181815b8085111561197757816000190482111561195d5761195d6118d9565b8085161561196a57918102915b93841c9390800290611941565b509250929050565b60008261198e57506001610692565b8161199b57506000610692565b81600181146119b157600281146119bb576119d7565b6001915050610692565b60ff8411156119cc576119cc6118d9565b50506001821b610692565b5060208310610133831016604e8410600b84101617156119fa575081810a610692565b611a04838361193c565b8060001904821115611a1857611a186118d9565b029392505050565b600061077b60ff84168361197f565b600060208284031215611a4157600080fd5b5051919050565b634e487b7160e01b600052601260045260246000fd5b81810381811115610692576106926118d9565b600060208284031215611a8357600080fd5b815161077b816117f3565b634e487b7160e01b600052602160045260246000fd5b600060ff831680611ac557634e487b7160e01b600052601260045260246000fd5b8060ff84160691505092915050565b60008251611ae68184602087016116d5565b919091019291505056fea26469706673582212200c601f6cd741d9a270930dffea899f43a60713a55c242b2766b6d2c97d65364e64736f6c63430008170033a2646970667358221220b2fcae34d3d749052ee0ebda274e595069f18019a6ee1de87ca8c678f9efe02764736f6c63430008170033";
const isSuperArgs = (xs) => xs.length > 1;
class CredbullVaultFactory__factory extends ethers_1.ContractFactory {
    constructor(...args) {
        if (isSuperArgs(args)) {
            super(...args);
        }
        else {
            super(_abi, _bytecode, args[0]);
        }
    }
    deploy(owner, operator, overrides) {
        return super.deploy(owner, operator, overrides || {});
    }
    getDeployTransaction(owner, operator, overrides) {
        return super.getDeployTransaction(owner, operator, overrides || {});
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
exports.CredbullVaultFactory__factory = CredbullVaultFactory__factory;
CredbullVaultFactory__factory.bytecode = _bytecode;
CredbullVaultFactory__factory.abi = _abi;
