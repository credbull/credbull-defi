import { Wallet, utils } from 'ethers';

// Generates a Private Key and Address for `name`.
export const generateAddress = (name: string): { privateKey: string; address: string } => {
  const hash = utils.id(name);
  const hashBuffer = Buffer.from(hash.slice(2), 'hex');
  const paddedHash = utils.hexlify(utils.zeroPad(hashBuffer, 32));
  const privateKey = `${utils.hexlify(paddedHash)}`;
  const wallet = new Wallet(privateKey);
  return { privateKey, address: wallet.address };
};

// Asynchronous utility function for waiting.
export async function wait(ms: number): Promise<any> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
