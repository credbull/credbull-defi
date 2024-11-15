"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.metadata = void 0;
const getMetadata_1 = require("~~/utils/scaffold-eth/getMetadata");
exports.metadata = (0, getMetadata_1.getMetadata)({
    title: "Block Explorer",
    description: "Block Explorer created with 🏗 Scaffold-ETH 2",
});
const BlockExplorerLayout = ({ children }) => {
    return <>{children}</>;
};
exports.default = BlockExplorerLayout;
