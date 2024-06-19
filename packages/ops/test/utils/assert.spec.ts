import { expect, test } from '@playwright/test';
import { ZodError } from 'zod';

import { assertAddress, assertEmail, assertEmailOptional, assertUpsideVault } from '@/utils/assert';
import { generateRandomEmail } from '@/utils/generate';

test.describe('Asserting an email parameter with', async () => {
  test('a valid email should pass', async () => {
    expect(() => assertEmail('test@credbull.io')).toPass();
    expect(() => assertEmail('test+admin@credbull.io')).toPass();
    expect(() => assertEmail(generateRandomEmail('test'))).toPass();
  });

  test('an invalid email should fail', async () => {
    expect(() => assertEmail('prefix')).toThrow(ZodError);
    expect(() => assertEmail('domain.com')).toThrow(ZodError);
    expect(() => assertEmail('')).toThrow(ZodError);
    expect(() => assertEmail(' \t \n ')).toThrow(ZodError);
    expect(() => assertEmail('someone@here')).toThrow(ZodError);
    expect(() => assertEmail('no one@here.com')).toThrow(ZodError);
  });
});

test.describe('Asserting an optional email parameter with', async () => {
  test('a valid email should pass', async () => {
    expect(() => assertEmailOptional('test@credbull.io')).toPass();
    expect(() => assertEmailOptional('test+admin@credbull.io')).toPass();
    expect(() => assertEmailOptional(generateRandomEmail('test'))).toPass();
  });

  test('an invalid email should fail', async () => {
    expect(() => assertEmailOptional('prefix')).toThrow(ZodError);
    expect(() => assertEmailOptional('domain.com')).toThrow(ZodError);
    expect(() => assertEmailOptional(' \t \n ')).toThrow(ZodError);
    expect(() => assertEmailOptional('someone@here')).toThrow(ZodError);
    expect(() => assertEmailOptional('no one@here.com')).toThrow(ZodError);
  });

  test('a null, undefined or empty string should pass', async () => {
    expect(() => assertEmailOptional(undefined)).toPass();
    expect(() => assertEmailOptional(null)).toPass();
    expect(() => assertEmailOptional('')).toPass();
  });
});

function correctlyAcceptsAddress(subject: (address: string) => void) {
  for (const chr of '1234567890abcdefABCDEF') {
    const hex = chr.repeat(40);
    expect(() => subject(hex)).toPass();
    expect(() => subject('0x' + hex)).toPass();
  }
}

function correctlyRejectsAddress(subject: (address: string) => void) {
  expect(() => subject('')).toThrow(ZodError);
  expect(() => subject(' \t \n ')).toThrow(ZodError);

  for (const chr of 'ghijklmnopqrstuvwxyzGHIJKLMNOPQRSTUVWXYZ') {
    const notHex = chr.repeat(40);
    expect(() => subject(notHex)).toThrow(ZodError);
    expect(() => subject('0x' + notHex)).toThrow(ZodError);
  }
  for (const chr of '1234567890abcdefABCDEF') {
    const tooSmall = chr.repeat(39);
    const tooBig = chr.repeat(41);
    expect(() => subject(tooSmall)).toThrow(ZodError);
    expect(() => subject('0x' + tooSmall)).toThrow(ZodError);
    expect(() => subject(tooBig)).toThrow(ZodError);
    expect(() => subject('0x' + tooBig)).toThrow(ZodError);
  }
}

test.describe('Asserting an address parameter with', async () => {
  test('a valid address should pass', async () => {
    correctlyAcceptsAddress(assertAddress);
  });

  test('an invalid address should fail', async () => {
    correctlyRejectsAddress(assertAddress);
  });
});

test.describe('Asserting an Upside Vault Specifier with', async () => {
  test('a valid value should pass', async () => {
    expect(() => assertUpsideVault('self')).toPass();
    correctlyAcceptsAddress(assertUpsideVault);
  });

  test('an invalid value should fail', async () => {
    expect(() => assertUpsideVault('self ')).toThrow(ZodError);
    expect(() => assertUpsideVault('SELF')).toThrow(ZodError);
    correctlyRejectsAddress(assertUpsideVault);
  });
});
