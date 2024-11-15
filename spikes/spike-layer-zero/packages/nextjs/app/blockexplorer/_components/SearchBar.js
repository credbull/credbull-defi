"use strict";
"use client";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.SearchBar = void 0;
const react_1 = require("react");
const navigation_1 = require("next/navigation");
const viem_1 = require("viem");
const chains_1 = require("viem/chains");
const wagmi_1 = require("wagmi");
const SearchBar = () => {
    const [searchInput, setSearchInput] = (0, react_1.useState)("");
    const router = (0, navigation_1.useRouter)();
    const client = (0, wagmi_1.usePublicClient)({ chainId: chains_1.hardhat.id });
    const handleSearch = (event) => __awaiter(void 0, void 0, void 0, function* () {
        event.preventDefault();
        if ((0, viem_1.isHex)(searchInput)) {
            try {
                const tx = yield (client === null || client === void 0 ? void 0 : client.getTransaction({ hash: searchInput }));
                if (tx) {
                    router.push(`/blockexplorer/transaction/${searchInput}`);
                    return;
                }
            }
            catch (error) {
                console.error("Failed to fetch transaction:", error);
            }
        }
        if ((0, viem_1.isAddress)(searchInput)) {
            router.push(`/blockexplorer/address/${searchInput}`);
            return;
        }
    });
    return (<form onSubmit={handleSearch} className="flex items-center justify-end mb-5 space-x-3 mx-5">
      <input className="border-primary bg-base-100 text-base-content p-2 mr-2 w-full md:w-1/2 lg:w-1/3 rounded-md shadow-md focus:outline-none focus:ring-2 focus:ring-accent" type="text" value={searchInput} placeholder="Search by hash or address" onChange={e => setSearchInput(e.target.value)}/>
      <button className="btn btn-sm btn-primary" type="submit">
        Search
      </button>
    </form>);
};
exports.SearchBar = SearchBar;
