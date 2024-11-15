"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.AddressComponent = void 0;
const BackButton_1 = require("./BackButton");
const ContractTabs_1 = require("./ContractTabs");
const scaffold_eth_1 = require("~~/components/scaffold-eth");
const AddressComponent = ({ address, contractData, }) => {
    return (<div className="m-10 mb-20">
      <div className="flex justify-start mb-5">
        <BackButton_1.BackButton />
      </div>
      <div className="col-span-5 grid grid-cols-1 lg:grid-cols-2 gap-8 lg:gap-10">
        <div className="col-span-1 flex flex-col">
          <div className="bg-base-100 border-base-300 border shadow-md shadow-secondary rounded-3xl px-6 lg:px-8 mb-6 space-y-1 py-4 overflow-x-auto">
            <div className="flex">
              <div className="flex flex-col gap-1">
                <scaffold_eth_1.Address address={address} format="long"/>
                <div className="flex gap-1 items-center">
                  <span className="font-bold text-sm">Balance:</span>
                  <scaffold_eth_1.Balance address={address} className="text"/>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
      <ContractTabs_1.ContractTabs address={address} contractData={contractData}/>
    </div>);
};
exports.AddressComponent = AddressComponent;
