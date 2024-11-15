"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.metadata = void 0;
const DebugContracts_1 = require("./_components/DebugContracts");
const getMetadata_1 = require("~~/utils/scaffold-eth/getMetadata");
exports.metadata = (0, getMetadata_1.getMetadata)({
    title: "Debug Contracts",
    description: "Debug your deployed 🏗 Scaffold-ETH 2 contracts in an easy way",
});
const Debug = () => {
    return (<>
      <DebugContracts_1.DebugContracts />
      <div className="text-center mt-8 bg-secondary p-10">
        <h1 className="text-4xl my-0">Debug Contracts</h1>
        <p className="text-neutral">
          You can debug & interact with your deployed contracts here.
          <br /> Check{" "}
          <code className="italic bg-base-300 text-base font-bold [word-spacing:-0.5rem] px-1">
            packages / nextjs / app / debug / page.tsx
          </code>{" "}
        </p>
      </div>
    </>);
};
exports.default = Debug;
