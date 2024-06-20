import crypto from 'crypto';
import { Wallet } from 'ethers';

export function generateAddress() {
  const id = crypto.randomBytes(32).toString('hex');
  const privateKey = '0x' + id;

  const wallet = new Wallet(privateKey);
  return wallet.address;
}

export function generatePassword(
  length = 15,
  characters = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz~!@-#$',
) {
  return Array.from(crypto.getRandomValues(new Uint32Array(length)))
    .map((x) => characters[x % characters.length])
    .join('');
}

export function generateRandomEmail(prefix: string): string {
  const randomString = Math.random().toString(36).substring(2, 10); // Generates a weak, pseudorandom string
  const domain = '@credbull.io';
  return `${prefix}+${randomString}${domain}`;
}
