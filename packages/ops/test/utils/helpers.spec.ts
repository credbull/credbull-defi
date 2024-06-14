import { expect, test } from '@playwright/test';
import { ZodError, z } from 'zod';

import { main } from '@/make-admin';

import { generateRandomEmail, parseEmail, parseEmailOptional } from '../../src/utils/helpers';

// Adjust the path as necessary

test('Test parse email', async () => {
  // const emailSchema = z.string().email().optional();

  // Test valid email
  // Test valid email
  expect(() => parseEmail('test@credbull.io')).not.toThrow();
  expect(() => parseEmail('test+admin@credbull.io')).not.toThrow();
  expect(() => parseEmail(generateRandomEmail('test'))).not.toThrow();

  expect(() => parseEmail(undefined)).toThrow(ZodError);
  expect(() => parseEmail('prefix')).toThrow(ZodError);
  expect(() => parseEmail('domain.com')).toThrow(ZodError);

  expect(() => parseEmail('')).toThrow(ZodError);
  expect(() => parseEmail(' \t \n ')).toThrow(ZodError);
  expect(() => parseEmail('someone@here')).toThrow(ZodError);
  expect(() => parseEmail('no one@here.com')).toThrow(ZodError);
});

test('Test parse optional email', async () => {
  expect(() => parseEmail('someone@here')).toThrow(ZodError);

  // Test invalid email
  expect(() => parseEmailOptional(undefined)).not.toThrow(ZodError);

  expect(() => parseEmailOptional(null)).not.toThrow(ZodError);
  expect(() => parseEmailOptional('')).not.toThrow(ZodError);
});