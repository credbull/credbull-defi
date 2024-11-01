import { useEffect, useState } from "react";
import { ethers } from "ethers";
import { useChainId, useChains, useReadContract } from "wagmi";
import { Contract, ContractAbi, ContractName } from "~~/utils/scaffold-eth/contract";

export const useFetchAdminData = ({
  userAccount,
  custodian,
  deployedContractAddress,
  deployedContractAbi,
  simpleUsdcContractData,
  dependencies = [],
}: {
  userAccount: string;
  custodian: string;
  deployedContractAddress: string;
  deployedContractAbi: ContractAbi;
  simpleUsdcContractData: Contract<ContractName> | undefined;
  dependencies: [any] | [];
}) => {
  const chains = useChains();
  const chianId = useChainId();

  const chain = chains?.filter(_chain => _chain?.id === chianId)[0];

  const [allDataFetched, setAllDataFetched] = useState<boolean>(false);

  const [vaultBalance, setVaultBalance] = useState<string>("");
  const [custodianBalance, setCustodianBalance] = useState<string>("");

  const [fetchingAdmins, setFetchingAdmins] = useState<boolean>(false);
  const [adminRole, setAdminRole] = useState<`0x${string}` | undefined>("0x");
  const [adminRoleCount, setAdminRoleCount] = useState<number>(0);
  const [adminRoleMembers, setAdminRoleMembers] = useState<string[]>([]);
  const [userHasAdminRole, setUserHasAdminRole] = useState<boolean>(false);

  const [fetchingOperators, setFetchingOperators] = useState<boolean>(false);
  const [operatorRole, setOperatorRole] = useState<`0x${string}` | undefined>("0x");
  const [operatorRoleCount, setOperatorRoleCount] = useState<number>(0);
  const [operatorRoleMembers, setOperatorRoleMembers] = useState<string[]>([]);
  const [userHasOperatorRole, setUserHasOperatorRole] = useState<boolean>(false);

  const [fetchingUpgraders, setFetchingUpgraders] = useState<boolean>(false);
  const [upgraderRole, setUpgraderRole] = useState<`0x${string}` | undefined>("0x");
  const [upgraderRoleCount, setUpgraderRoleCount] = useState<number>(0);
  const [upgraderRoleMembers, setUpgraderRoleMembers] = useState<string[]>([]);
  const [userHasUpgraderRole, setUserHasUpgraderRole] = useState<boolean>(false);

  const [fetchingAssetManagers, setFetchingAssetManagers] = useState<boolean>(false);
  const [assetManagerRole, setAssetManagerRole] = useState<`0x${string}` | undefined>("0x");
  const [assetManagerRoleCount, setAssetManagerRoleCount] = useState<number>(0);
  const [assetManagerRoleMembers, setAssetManagerRoleMembers] = useState<string[]>([]);
  const [userHasAssetManagerRole, setUserHasAssetManagerRole] = useState<boolean>(false);

  // const provider = useCallback(
  //   () => new ethers.JsonRpcProvider(chain?.rpcUrls?.default?.http[0]),
  //   [chain?.rpcUrls?.default?.http],
  // );

  const { refetch: refetchVaultBalance } = useReadContract({
    address: simpleUsdcContractData?.address,
    functionName: "balanceOf",
    abi: simpleUsdcContractData?.abi,
    args: [deployedContractAddress],
  });

  const { refetch: refetchCustodianBalance } = useReadContract({
    address: simpleUsdcContractData?.address,
    functionName: "balanceOf",
    abi: simpleUsdcContractData?.abi,
    args: [custodian],
  });

  const { refetch: refetchUserHasAdminRole } = useReadContract({
    address: deployedContractAddress,
    functionName: "hasRole",
    abi: deployedContractAbi,
    args: [adminRole?.toString() || "", userAccount],
  });

  const { refetch: refetchUserHasOperatorRole } = useReadContract({
    address: deployedContractAddress,
    functionName: "hasRole",
    abi: deployedContractAbi,
    args: [operatorRole?.toString() || "", userAccount],
  });

  const { refetch: refetchUserHasUpgraderRole } = useReadContract({
    address: deployedContractAddress,
    functionName: "hasRole",
    abi: deployedContractAbi,
    args: [upgraderRole?.toString() || "", userAccount],
  });

  const { refetch: refetchUserHasAssetManagerRole } = useReadContract({
    address: deployedContractAddress,
    functionName: "hasRole",
    abi: deployedContractAbi,
    args: [assetManagerRole?.toString() || "", userAccount],
  });

  const { refetch: refetchAdminRole } = useReadContract({
    address: deployedContractAddress,
    functionName: "DEFAULT_ADMIN_ROLE",
    abi: deployedContractAbi,
    args: [],
  });

  const { refetch: refetchAdminRoleCount } = useReadContract({
    address: deployedContractAddress,
    functionName: "getRoleMemberCount",
    abi: deployedContractAbi,
    args: [adminRole?.toString() || ""],
  });

  const { refetch: refetchOperatorRole } = useReadContract({
    address: deployedContractAddress,
    functionName: "OPERATOR_ROLE",
    abi: deployedContractAbi,
    args: [],
  });

  const { refetch: refetchOperatorRoleCount } = useReadContract({
    address: deployedContractAddress,
    functionName: "getRoleMemberCount",
    abi: deployedContractAbi,
    args: [operatorRole?.toString() || ""],
  });

  const { refetch: refetchUpgraderRole } = useReadContract({
    address: deployedContractAddress,
    functionName: "UPGRADER_ROLE",
    abi: deployedContractAbi,
    args: [],
  });

  const { refetch: refetchUpgraderRoleCount } = useReadContract({
    address: deployedContractAddress,
    functionName: "getRoleMemberCount",
    abi: deployedContractAbi,
    args: [upgraderRole?.toString() || ""],
  });

  const { refetch: refetchAssetManagerRole } = useReadContract({
    address: deployedContractAddress,
    functionName: "ASSET_MANAGER_ROLE",
    abi: deployedContractAbi,
    args: [],
  });

  const { refetch: refetchAssetManagerRoleCount } = useReadContract({
    address: deployedContractAddress,
    functionName: "getRoleMemberCount",
    abi: deployedContractAbi,
    args: [assetManagerRole?.toString() || ""],
  });

  // Fetch data and set state
  useEffect(() => {
    const fetchData = async () => {
      if (
        !deployedContractAddress ||
        !deployedContractAbi ||
        !chain?.rpcUrls?.default?.http[0] ||
        !simpleUsdcContractData
      ) {
        return;
      }

      try {
        const provider = new ethers.JsonRpcProvider(chain?.rpcUrls?.default?.http[0]);
        const deployedContract = new ethers.Contract(deployedContractAddress, deployedContractAbi, provider);

        setFetchingAdmins(true);
        setFetchingOperators(true);
        setFetchingUpgraders(true);
        setFetchingAssetManagers(true);

        const vaultBalanceData = await refetchVaultBalance();
        const vaultBalanceBigInt = BigInt(vaultBalanceData?.data as bigint);
        setVaultBalance(ethers.formatUnits(vaultBalanceBigInt, 6));

        const custodianData = await refetchCustodianBalance();
        const custodianBigInt = BigInt(custodianData?.data as bigint);
        setCustodianBalance(ethers.formatUnits(custodianBigInt, 6));

        const adminRoleData = await refetchAdminRole();

        setAdminRole(adminRoleData?.data as `0x${string}`);

        const adminRoleCountData = await refetchAdminRoleCount();

        setAdminRoleCount(Number(adminRoleCountData?.data));

        const userHasAdminRoleData = await refetchUserHasAdminRole();

        setUserHasAdminRole((userHasAdminRoleData?.data || false) as boolean);

        const operatorRoleData = await refetchOperatorRole();

        setOperatorRole(operatorRoleData?.data as `0x${string}`);

        const operatorRoleCountData = await refetchOperatorRoleCount();

        setOperatorRoleCount(Number(operatorRoleCountData?.data));

        const upgraderRoleData = await refetchUpgraderRole();

        const userHasOperatorRoleData = await refetchUserHasOperatorRole();

        setUserHasOperatorRole((userHasOperatorRoleData?.data || false) as boolean);

        setUpgraderRole(upgraderRoleData?.data as `0x${string}`);

        const upgraderRoleCountData = await refetchUpgraderRoleCount();

        setUpgraderRoleCount(Number(upgraderRoleCountData?.data));

        const assetManagerRoleData = await refetchAssetManagerRole();

        const userHasUpgraderRoleData = await refetchUserHasUpgraderRole();

        setUserHasUpgraderRole((userHasUpgraderRoleData?.data || false) as boolean);

        setAssetManagerRole(assetManagerRoleData?.data as `0x${string}`);

        const assetManagerRoleCountData = await refetchAssetManagerRoleCount();

        setAssetManagerRoleCount(Number(assetManagerRoleCountData?.data));

        const userHasAssetManagerRoleData = await refetchUserHasAssetManagerRole();

        setUserHasAssetManagerRole((userHasAssetManagerRoleData?.data || false) as boolean);

        if (deployedContract && adminRoleData && adminRoleCountData) {
          const _adminRoleMembers: string[] = [];

          for (let i = 0; i < Number(adminRoleCountData?.data); i++) {
            const adminRoleMember = await deployedContract.getRoleMember(adminRoleData?.data, BigInt(i));

            _adminRoleMembers.push(adminRoleMember);
          }

          setAdminRoleMembers(_adminRoleMembers);
        }
        setFetchingAdmins(false);

        if (deployedContract && operatorRoleData && operatorRoleCountData) {
          const _operatorRoleMembers: string[] = [];

          for (let i = 0; i < Number(operatorRoleCountData?.data); i++) {
            const operatorRoleMember = await deployedContract.getRoleMember(operatorRoleData?.data, BigInt(i));

            _operatorRoleMembers.push(operatorRoleMember);
          }

          setOperatorRoleMembers(_operatorRoleMembers);
        }
        setFetchingOperators(false);

        if (deployedContract && upgraderRoleData && upgraderRoleCountData) {
          const _upgraderRoleMembers: string[] = [];

          for (let i = 0; i < Number(upgraderRoleCountData?.data); i++) {
            const upgraderRoleMember = await deployedContract.getRoleMember(upgraderRoleData?.data, BigInt(i));

            _upgraderRoleMembers.push(upgraderRoleMember);
          }

          setUpgraderRoleMembers(_upgraderRoleMembers);
        }
        setFetchingUpgraders(false);

        if (deployedContract && assetManagerRoleData && assetManagerRoleCountData) {
          const _assetManagerRoleMembers: string[] = [];

          for (let i = 0; i < Number(assetManagerRoleCountData?.data); i++) {
            const assetManagerRoleMember = await deployedContract.getRoleMember(assetManagerRoleData?.data, BigInt(i));

            _assetManagerRoleMembers.push(assetManagerRoleMember);
          }

          setAssetManagerRoleMembers(_assetManagerRoleMembers);
        }
        setFetchingAssetManagers(false);

        setAllDataFetched(true);
      } catch (error) {
        setAllDataFetched(true);
      }
    };

    fetchData();
  }, [
    userAccount,
    deployedContractAddress,
    chain?.rpcUrls?.default?.http,
    simpleUsdcContractData,
    vaultBalance,
    custodianBalance,
    deployedContractAbi,
    refetchAdminRole,
    refetchAdminRoleCount,
    refetchAssetManagerRole,
    refetchAssetManagerRoleCount,
    refetchCustodianBalance,
    refetchOperatorRole,
    refetchOperatorRoleCount,
    refetchUpgraderRole,
    refetchUpgraderRoleCount,
    refetchUserHasAdminRole,
    refetchUserHasAssetManagerRole,
    refetchUserHasOperatorRole,
    refetchUserHasUpgraderRole,
    refetchVaultBalance,
    ...dependencies,
  ]);

  return {
    allDataFetched,
    vaultBalance,
    custodianBalance,
    adminRole,
    adminRoleCount,
    adminRoleMembers,
    userHasAdminRole,
    operatorRole,
    operatorRoleCount,
    operatorRoleMembers,
    userHasOperatorRole,
    upgraderRole,
    upgraderRoleCount,
    upgraderRoleMembers,
    userHasUpgraderRole,
    assetManagerRole,
    assetManagerRoleCount,
    assetManagerRoleMembers,
    userHasAssetManagerRole,
    fetchingAdmins,
    fetchingOperators,
    fetchingUpgraders,
    fetchingAssetManagers,
  };
};
