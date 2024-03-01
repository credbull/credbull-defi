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
var __importDefault =
  (this && this.__importDefault) ||
  function (mod) {
    return mod && mod.__esModule ? mod : { default: mod };
  };
Object.defineProperty(exports, '__esModule', { value: true });
exports.__mockMint =
  exports.decodeError =
  exports.generateSigner =
  exports.generateAddress =
  exports.signer =
  exports.login =
  exports.headers =
    void 0;
const contracts_1 = require('@credbull/contracts');
const crypto_1 = __importDefault(require('crypto'));
const ethers_1 = require('ethers');
const headers = (session) => {
  return {
    headers: Object.assign(
      { 'Content-Type': 'application/json' },
      (session === null || session === void 0 ? void 0 : session.access_token)
        ? { Authorization: `Bearer ${session.access_token}` }
        : {},
    ),
  };
};
exports.headers = headers;
const login = (email, password) =>
  __awaiter(void 0, void 0, void 0, function* () {
    const body = JSON.stringify({
      email: email,
      password: password,
    });
    const signIn = yield fetch(
      `http://localhost:3001/auth/api/sign-in`,
      Object.assign({ method: 'POST', body }, (0, exports.headers)()),
    );
    return signIn.json();
  });
exports.login = login;
const signer = (privateKey) => {
  return new ethers_1.Wallet(privateKey, new ethers_1.providers.JsonRpcProvider(`http://localhost:8545`));
};
exports.signer = signer;
const generateAddress = () => {
  const id = crypto_1.default.randomBytes(32).toString('hex');
  const privateKey = '0x' + id;
  const wallet = new ethers_1.Wallet(privateKey);
  return wallet.address;
};
exports.generateAddress = generateAddress;
const generateSigner = () => {
  const id = crypto_1.default.randomBytes(32).toString('hex');
  const privateKey = '0x' + id;
  return new ethers_1.Wallet(privateKey, new ethers_1.providers.JsonRpcProvider(`http://localhost:8545`));
};
exports.generateSigner = generateSigner;
const decodeError = (contract, err) => {
  const contractInterface = contract.interface;
  const selecter = err.slice(0, 10);
  const res = contractInterface.decodeErrorResult(selecter, err);
  const errorName = contractInterface.getError(selecter).name;
  console.log(errorName);
  console.log(res.toString());
};
exports.decodeError = decodeError;
const __mockMint = (to, amount, vault, signer) =>
  __awaiter(void 0, void 0, void 0, function* () {
    const assetAddress = yield vault.asset();
    const asset = contracts_1.MockStablecoin__factory.connect(assetAddress, signer);
    yield asset.mint(to, amount);
  });
exports.__mockMint = __mockMint;
