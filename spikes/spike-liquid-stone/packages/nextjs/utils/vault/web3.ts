import { Alchemy, AlchemySettings, Network, OwnedNft } from "alchemy-sdk";

export async function getNFTsForOwner(chainId: number, owner: string, contract: string) {
  if ([31337, 98864].includes(chainId)) {
    return {
      nfts: Array.from(
        { length: 101 },
        (_, index) =>
          ({
            tokenId: index.toString(),
          } as OwnedNft),
      ),
      fetchedWithAlchemy: false,
    };
  } else {
    let chain: Network;

    switch (chainId) {
      case 421614:
        chain = Network.ARB_SEPOLIA;
        break;
      default:
        chain = Network.ARB_SEPOLIA;
        break;
    }

    const settings: AlchemySettings = {
      apiKey: process.env.NEXT_PUBLIC_ALCHEMY_API_KEY,
      network: chain,
    };

    const alchemy = new Alchemy(settings);

    const nfts = await alchemy.nft.getNftsForOwner(owner, {
      contractAddresses: [contract],
    });

    const filteredNfts = nfts.ownedNfts.filter(nft => nft.tokenType === "ERC1155");

    const erc1155Tokens: OwnedNft[] = filteredNfts.map(
      token =>
        ({
          tokenId: token?.tokenId,
          balance: token?.balance,
        } as OwnedNft),
    );

    return { nfts: erc1155Tokens, fetchedWithAlchemy: true };
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
