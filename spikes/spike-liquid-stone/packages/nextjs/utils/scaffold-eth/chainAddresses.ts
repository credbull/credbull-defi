export interface ChainAddresses {
  credbullCustody: string; // address able to receive assets, e.g. from LiquidStone
}

export const testnetCredbullDevops: ChainAddresses = {
  credbullCustody: "0x8561845F6a9511cD8e2daCae77A961e718A77cF6", // devops custodian (wallet 3)
};

export const primvevaultCredbullDefi: ChainAddresses = {
  credbullCustody: "0xce694E94e1Ddb734f2bD32B2511D193fF2783FB2", // primevault [0xce..3FB2] "Credbull DeFi Vault - Treasury v1.0"
};

export const plumeMainnetSafe: ChainAddresses = {
  credbullCustody: "0x120Fa6e272Ea84BB00a11A816b8b759a5f6f2171", // Plume Safe https://safe.onchainden.com/home?safe=plume:0x120Fa6e272Ea84BB00a11A816b8b759a5f6f2171
};