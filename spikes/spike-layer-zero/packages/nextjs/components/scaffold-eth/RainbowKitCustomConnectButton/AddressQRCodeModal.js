"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.AddressQRCodeModal = void 0;
const qrcode_react_1 = require("qrcode.react");
const scaffold_eth_1 = require("~~/components/scaffold-eth");
const AddressQRCodeModal = ({ address, modalId }) => {
    return (<>
      <div>
        <input type="checkbox" id={`${modalId}`} className="modal-toggle"/>
        <label htmlFor={`${modalId}`} className="modal cursor-pointer">
          <label className="modal-box relative">
            {/* dummy input to capture event onclick on modal box */}
            <input className="h-0 w-0 absolute top-0 left-0"/>
            <label htmlFor={`${modalId}`} className="btn btn-ghost btn-sm btn-circle absolute right-3 top-3">
              ✕
            </label>
            <div className="space-y-3 py-6">
              <div className="flex flex-col items-center gap-6">
                <qrcode_react_1.QRCodeSVG value={address} size={256}/>
                <scaffold_eth_1.Address address={address} format="long" disableAddressLink/>
              </div>
            </div>
          </label>
        </label>
      </div>
    </>);
};
exports.AddressQRCodeModal = AddressQRCodeModal;
