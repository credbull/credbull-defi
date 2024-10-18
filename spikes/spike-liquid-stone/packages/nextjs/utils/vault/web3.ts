import { Alchemy, AlchemySettings, Network } from "alchemy-sdk";

export async function getNFTsForOwner(chain: number, owner: string, contract: string) {
  if (chain === 31337) {
    return Array.from({ length: 1001 }, (_, index) => index);
  } else {
    const settings: AlchemySettings = {
      apiKey: process.env.ALCHEMY_API_KEY,
      network: Network.ETH_MAINNET,
    };

    const alchemy = new Alchemy(settings);

    const nfts = await alchemy.nft.getNftsForOwner(owner, {
      contractAddresses: [contract],
    });

    const erc1155Tokens = nfts.ownedNfts.filter(nft => nft.tokenType === "ERC1155");

    return erc1155Tokens;
  }
}

export function parseUnits(value: string, decimals = 6) {
  const multiplier = BigInt(10 ** decimals);
  const [integerPart, fractionalPart = "0"] = value.toString().split(".");
  const integerValue = BigInt(integerPart) * multiplier;
  const fractionalValue = BigInt(fractionalPart.padEnd(decimals, "0").slice(0, decimals));
  return integerValue + fractionalValue;
}

export function parseEther(value: string) {
  return parseUnits(value, 18);
}

export function formatUnits(value: bigint, decimals = 6) {
  const divisor = BigInt(10 ** decimals);
  const integerPart = (value / divisor).toString();
  const fractionalPart = (value % divisor).toString().padStart(decimals, "0").replace(/0+$/, "");
  return fractionalPart ? `${integerPart}.${fractionalPart}` : integerPart;
}

export function formatEther(value: bigint) {
  return formatUnits(value, 18);
}
