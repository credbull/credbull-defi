# Helper Scripts

## User Related
```bash
# create a user
yarn op --create-user channel:false email:<<user@domain.com>>
```

```bash
# make a user admin
yarn op --make-admin null email:<<user@domain.com>>
```


## Vault Related

```bash
# create a "default" vault (open, not matured)
yarn op --create-vault
```

```bash
# TODO - fix this!
# create an matured and upside vault
yarn op --create-vault matured,upside upsideVault:self
```

