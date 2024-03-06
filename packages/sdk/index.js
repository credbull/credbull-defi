'use strict';
var __awaiter =
  (this && this.__awaiter) ||
  function (thisArg, _arguments, P, generator) {
    function adopt(value) {
      return value instanceof P
        ? value
        : new P(function (resolve) {
            resolve(value);
          });
    }
    return new (P || (P = Promise))(function (resolve, reject) {
      function fulfilled(value) {
        try {
          step(generator.next(value));
        } catch (e) {
          reject(e);
        }
      }
      function rejected(value) {
        try {
          step(generator['throw'](value));
        } catch (e) {
          reject(e);
        }
      }
      function step(result) {
        result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected);
      }
      step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
  };
Object.defineProperty(exports, '__esModule', { value: true });
exports.CredbullSDK = void 0;
const contracts_1 = require('@credbull/contracts');
const siwe_1 = require('siwe');
const utils_1 = require('./src/utils/utils');
class CredbullSDK {
  constructor(access_token, signer) {
    this.access_token = access_token;
    this.signer = signer;
    this.SERVICE_URL = 'http://localhost:3001';
  }
  headers() {
    return {
      headers: Object.assign(
        { 'Content-Type': 'application/json' },
        this.access_token ? { Authorization: `Bearer ${this.access_token}` } : {},
      ),
    };
  }
  linkWalletMessage(signer) {
    return __awaiter(this, void 0, void 0, function* () {
      const chainId = yield signer.getChainId();
      const preMessage = new siwe_1.SiweMessage({
        domain: this.SERVICE_URL.split('//')[1],
        address: yield signer.getAddress(),
        statement: 'By connecting your wallet, you agree to the Terms of Service and Privacy Policy.',
        uri: 'http://localhost:3001',
        version: '1',
        chainId,
        nonce: (0, siwe_1.generateNonce)(),
      });
      return preMessage.prepareMessage();
    });
  }
  handleError(contract, error) {
    var _a, _b, _c, _d, _e;
    if (
      (_b = (_a = error.error) === null || _a === void 0 ? void 0 : _a.data) === null || _b === void 0
        ? void 0
        : _b.data
    ) {
      (0, utils_1.decodeContractError)(contract, error.error.data.data);
    } else if (
      (_e =
        (_d = (_c = error.error) === null || _c === void 0 ? void 0 : _c.error) === null || _d === void 0
          ? void 0
          : _d.error) === null || _e === void 0
        ? void 0
        : _e.data
    ) {
      (0, utils_1.decodeContractError)(contract, error.error.error.error.data);
    } else {
      throw error;
    }
  }
  /// Return all active vaults
  getAllVaults() {
    return __awaiter(this, void 0, void 0, function* () {
      const vaultsData = yield fetch(
        `${this.SERVICE_URL}/vaults/current`,
        Object.assign({ method: 'GET' }, this.headers()),
      );
      return yield vaultsData.json();
    });
  }
  /// Link user wallet
  linkWallet(discriminator) {
    return __awaiter(this, void 0, void 0, function* () {
      const message = yield this.linkWalletMessage(this.signer);
      const signature = yield this.signer.signMessage(message);
      const linkWallet = yield fetch(
        `${this.SERVICE_URL}/accounts/link-wallet`,
        Object.assign({ method: 'POST', body: JSON.stringify({ message, signature, discriminator }) }, this.headers()),
      );
      return yield linkWallet.json();
    });
  }
  /// Deposit token to the given vault address
  deposit(vaultAddress, amount, receiver) {
    return __awaiter(this, void 0, void 0, function* () {
      const vault = contracts_1.CredbullFixedYieldVault__factory.connect(vaultAddress, this.signer);
      yield vault.deposit(amount, receiver).catch((err) => this.handleError(vault, err));
    });
  }
  /// Redeem the share tokens
  redeem(vaultAddress, shares, receiver) {
    return __awaiter(this, void 0, void 0, function* () {
      const vault = contracts_1.CredbullFixedYieldVault__factory.connect(vaultAddress, this.signer);
      yield vault.redeem(shares, receiver, receiver).catch((err) => this.handleError(vault, err));
    });
  }
  /// Get the instance of an asset associated with the vault
  getAssetInstance(vaultAddress) {
    return __awaiter(this, void 0, void 0, function* () {
      const vault = contracts_1.CredbullFixedYieldVault__factory.connect(vaultAddress, this.signer);
      const assetAddress = yield vault.asset().catch((err) => this.handleError(vault, err));
      return contracts_1.ERC20__factory.connect(assetAddress, this.signer);
    });
  }
  /// Get the instance of the vault
  getVaultInstance(vaultAddress) {
    return __awaiter(this, void 0, void 0, function* () {
      return contracts_1.CredbullFixedYieldVault__factory.connect(vaultAddress, this.signer);
    });
  }
  getTokenInstance(vaultAddress) {
    return __awaiter(this, void 0, void 0, function* () {
      const vault = contracts_1.CredbullFixedYieldVaultWithUpside__factory.connect(vaultAddress, this.signer);
      const tokenAddress = yield vault.token().catch((err) => this.handleError(vault, err));
      return contracts_1.ERC20__factory.connect(tokenAddress, this.signer);
    });
  }
}
exports.CredbullSDK = CredbullSDK;
