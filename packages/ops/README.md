# Helper Scripts

## OVERALL
**PREREQUISITES**:
1. api/supabase start
1. api/yarn dev
1. contracts/yarn chain
1. contracts/yarn deploy


## Setup Users
```bash
# AND/OR create some sample users (these should be reflected in your .env.local)
yarn op --create-default-users

# create a named user, e.g. admin-user@credbull.io
yarn op --create-user channel:false email:admin-user@credbull.io

# make a user an admin, e.g. e.g. admin-user@credbull.io
yarn op --make-admin null email:admin-user@credbull.io

# manually link a wallet via front-end
# TODO - automate this step
```

## Create Vaults
**PREREQUISITES**:
1. Setup users as per above or equivalent
1. Ensure create-vault op script runs as a VaultFactory ADMIN to allow custodians (set Env ADMIN_* variables in packages/ops/.env)
1. Ensure create-vault API runs as the Vault OPERATOR to Create Vaults (see Env use in [`ethers.service.ts/`](../api/src/clients/ethers/ethers.service.ts))

```bash
# create a vault with minimal config (open vault, not matured)
yarn op --create-vault
```

```bash
# TODO - fix this!
# create an matured and upside vault
yarn op --create-vault matured,upside upsideVault:self
```
