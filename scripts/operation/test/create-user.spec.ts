import { z, ZodError } from 'zod';
import { test, expect, type Page } from '@playwright/test';

import { createUser } from '../src/create-user';
import { loadConfiguration } from '../src/utils/config';

const EMAIL_ADDRESS = 'admin@under.test';
const PASSWORD = 'DoNotForget';
const EMPTY_CONFIG = {};

let config: any | undefined = undefined;

test.beforeAll(() => {
  // NOTE (JL,2024-05-31): This loads the same configuration as the operations themselves.
  config = loadConfiguration();
});

test.describe('Create User', async () => {

  test('should fail with an invalid configuration', async () => {
    expect(createUser(EMPTY_CONFIG, EMAIL_ADDRESS, false)).rejects.toThrow(ZodError);
    expect(createUser('I Am Config', EMAIL_ADDRESS, false)).rejects.toThrow(ZodError);
    expect(createUser(42, EMAIL_ADDRESS, false)).rejects.toThrow(ZodError);
  });

  test('should fail with an invalid email address', async () => {
    expect(createUser(config, '', false)).rejects.toThrow(ZodError);
    expect(createUser(config, ' \t \n ', false)).rejects.toThrow(ZodError);
    expect(createUser(config, 'someone@here', false)).rejects.toThrow(ZodError);
    expect(createUser(config, 'no one@here.com', false)).rejects.toThrow(ZodError);
  });

  test('testing testing 1 2', async () => {
    const emailSchema = z.string().email();
    const nonEmptyStringSchema = z.string().trim().min(1);

    expect(() => { nonEmptyStringSchema.parse('') }).toThrow(ZodError);
    expect(() => { nonEmptyStringSchema.parse('   \t \n ') }).toThrow();
    expect(() => { nonEmptyStringSchema.parse(undefined) }).toThrow();

    expect(() => { nonEmptyStringSchema.optional().parse('') }).toThrow(ZodError);
    expect(() => { nonEmptyStringSchema.optional().parse('   \t \n ') }).toThrow();
    expect(() => { nonEmptyStringSchema.optional().parse(undefined) }).toPass();
  });

});
