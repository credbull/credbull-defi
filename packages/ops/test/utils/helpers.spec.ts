import { expect, test } from '@playwright/test';
import { ZodError } from 'zod';

import { generateRandomEmail, parseEmail, parseEmailOptional, parseUpsideVault } from '../../src/utils/helpers';

test.describe('Parsing an email parameter with', async () => {
  test('a valid email should pass', async () => {
    expect(() => parseEmail('test@credbull.io')).toPass();
    expect(() => parseEmail('test+admin@credbull.io')).toPass();
    expect(() => parseEmail(generateRandomEmail('test'))).toPass();
  });

  test('an invalid email should fail', async () => {
    expect(() => parseEmail('prefix')).toThrow(ZodError);
    expect(() => parseEmail('domain.com')).toThrow(ZodError);
    expect(() => parseEmail('')).toThrow(ZodError);
    expect(() => parseEmail(' \t \n ')).toThrow(ZodError);
    expect(() => parseEmail('someone@here')).toThrow(ZodError);
    expect(() => parseEmail('no one@here.com')).toThrow(ZodError);
  });
});

test.describe('Parsing an optional email parameter with', async () => {
  test('a valid email should pass', async () => {
    expect(() => parseEmailOptional('test@credbull.io')).toPass();
    expect(() => parseEmailOptional('test+admin@credbull.io')).toPass();
    expect(() => parseEmailOptional(generateRandomEmail('test'))).toPass();
  });

  test('an invalid email should fail', async () => {
    expect(() => parseEmailOptional('prefix')).toThrow(ZodError);
    expect(() => parseEmailOptional('domain.com')).toThrow(ZodError);
    expect(() => parseEmailOptional(' \t \n ')).toThrow(ZodError);
    expect(() => parseEmailOptional('someone@here')).toThrow(ZodError);
    expect(() => parseEmailOptional('no one@here.com')).toThrow(ZodError);
  });

  test('a null, undefined or empty string should pass', async () => {
    expect(() => parseEmailOptional(undefined)).toPass();
    expect(() => parseEmailOptional(null)).toPass();
    expect(() => parseEmailOptional('')).toPass();
  });
});

test.describe('Parsing an Upside Vault Specifier with', async () => {
  test('a valid value should pass', async () => {
    expect(() => parseUpsideVault('self')).toPass();
    for (const chr of '1234567890abcdefABCDEF') {
      const hex = chr.repeat(40);
      expect(() => parseUpsideVault(hex)).toPass();
      expect(() => parseUpsideVault('0x' + hex)).toPass();
    }
  });

  test('an invalid value should fail', async () => {
    expect(() => parseUpsideVault('')).toThrow(ZodError);
    expect(() => parseUpsideVault(' \t \n ')).toThrow(ZodError);
    expect(() => parseUpsideVault('self ')).toThrow(ZodError);
    expect(() => parseUpsideVault('SELF')).toThrow(ZodError);

    for (const chr of 'ghijklmnopqrstuvwxyzGHIJKLMNOPQRSTUVWXYZ') {
      const notHex = chr.repeat(40);
      expect(() => parseUpsideVault(notHex)).toThrow(ZodError);
      expect(() => parseUpsideVault('0x' + notHex)).toThrow(ZodError);
    }
    for (const chr of '1234567890abcdefABCDEF') {
      const tooSmall = chr.repeat(39);
      const tooBig = chr.repeat(41);
      expect(() => parseUpsideVault(tooSmall)).toThrow(ZodError);
      expect(() => parseUpsideVault('0x' + tooSmall)).toThrow(ZodError);
      expect(() => parseUpsideVault(tooBig)).toThrow(ZodError);
      expect(() => parseUpsideVault('0x' + tooBig)).toThrow(ZodError);
    }
  });
});
