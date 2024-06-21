import { Schema } from './schema';

export function assertAddress(address: string) {
  Schema.ADDRESS.parse(address);
}

export function assertEmail(email: string) {
  Schema.EMAIL.parse(email);
}

export function assertEmailOptional(email?: string | null) {
  Schema.EMAIL_OPTIONAL.parse(email);
}

export function assertUpsideVault(upsideVaultSpec?: string) {
  Schema.UPSIDE_VAULT_SPEC.optional().parse(upsideVaultSpec);
}
