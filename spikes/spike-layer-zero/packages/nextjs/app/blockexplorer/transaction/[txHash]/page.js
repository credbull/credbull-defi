"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.generateStaticParams = generateStaticParams;
const TransactionComp_1 = __importDefault(require("../_components/TransactionComp"));
const common_1 = require("~~/utils/scaffold-eth/common");
function generateStaticParams() {
    // An workaround to enable static exports in Next.js, generating single dummy page.
    return [{ txHash: "0x0000000000000000000000000000000000000000" }];
}
const TransactionPage = ({ params }) => {
    const txHash = params === null || params === void 0 ? void 0 : params.txHash;
    if ((0, common_1.isZeroAddress)(txHash))
        return null;
    return <TransactionComp_1.default txHash={txHash}/>;
};
exports.default = TransactionPage;
