"use client";

import { useAccount } from "wagmi";
import ContractValueBadge from "~~/components/general/ContractValueBadge";
import LoadingSpinner from "~~/components/general/LoadingSpinner";
import { formatAddress } from "~~/utils/vault/general";

const UserDataSection = ({
  allDataFetched,
  userHasAdminRole,
  userHasOperatorRole,
  userHasUpgraderRole,
  userHasAssetManagerRole,
}: {
  allDataFetched: boolean;
  userHasAdminRole: boolean;
  userHasOperatorRole: boolean;
  userHasUpgraderRole: boolean;
  userHasAssetManagerRole: boolean;
}) => {
  const { address } = useAccount();

  return (
    <div className="flex items-center justify-between p-4 bg-gray-200 rounded-lg shadow-md">
      <div className="flex items-center gap-4">
        {address ? (
          <>
            <ContractValueBadge name="Connected Wallet" value={address ? formatAddress(address) : "No address found"} />
            {allDataFetched ? (
              <>
                <span className="text-black">|</span>
                {userHasAdminRole || userHasOperatorRole || userHasUpgraderRole || userHasAssetManagerRole ? (
                  <>
                    {userHasAdminRole && <ContractValueBadge value="Admin" />}
                    {userHasOperatorRole && <ContractValueBadge value="Operator" />}
                    {userHasUpgraderRole && <ContractValueBadge value="Upgrader" />}
                    {userHasAssetManagerRole && <ContractValueBadge value="Asset Manager" />}
                  </>
                ) : (
                  <ContractValueBadge theme="red" value="No role assigned" />
                )}
              </>
            ) : (
              <LoadingSpinner size="medium" textColor="black" />
            )}
          </>
        ) : (
          <ContractValueBadge theme="red" value="No wallet connected" />
        )}
      </div>
    </div>
  );
};

export default UserDataSection;
