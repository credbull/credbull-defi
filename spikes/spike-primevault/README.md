# spike-primevault

Spike of routing transactions to primevault for signing and relay

1. Generate a keypair
    ```bash
    yarn keygen
    ```
1. Create an API user in https://app.primevault.com/ 
1. Update .env with KEYS and Vault information
1. Run the preimvault sample code
    ```bash
   yarn spike:primevault
    ```
