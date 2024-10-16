import { useEffect, useState } from "react";
import { ethers } from "ethers";
import { useReadContract } from "wagmi";
import { Contract, ContractAbi, ContractName } from "~~/utils/scaffold-eth/contract";

export const useFetchAdminData = ({
  custodian,
  deployedContractAddress,
  deployedContractAbi,
  simpleUsdcContractData,
  dependencies = [],
}: {
  custodian: string;
  deployedContractAddress: string;
  deployedContractAbi: ContractAbi;
  simpleUsdcContractData: Contract<ContractName> | undefined;
  dependencies: [any] | [];
}) => {
  const [vaultBalance, setVaultBalance] = useState<string>("");
  const [custodianBalance, setCustodianBalance] = useState<string>("");

  const [fetchingAdmins, setFetchingAdmins] = useState<boolean>(false);
  const [adminRole, setAdminRole] = useState<`0x${string}` | undefined>("0x");
  const [adminRoleCount, setAdminRoleCount] = useState<number>(0);
  const [adminRoleMembers, setAdminRoleMembers] = useState<string[]>([]);

  const [fetchingOperators, setFetchingOperators] = useState<boolean>(false);
  const [operatorRole, setOperatorRole] = useState<`0x${string}` | undefined>("0x");
  const [operatorRoleCount, setOperatorRoleCount] = useState<number>(0);
  const [operatorRoleMembers, setOperatorRoleMembers] = useState<string[]>([]);

  const [fetchingUpgraders, setFetchingUpgraders] = useState<boolean>(false);
  const [upgraderRole, setUpgraderRole] = useState<`0x${string}` | undefined>("0x");
  const [upgraderRoleCount, setUpgraderRoleCount] = useState<number>(0);
  const [upgraderRoleMembers, setUpgraderRoleMembers] = useState<string[]>([]);

  const [fetchingAssetManagers, setFetchingAssetManagers] = useState<boolean>(false);
  const [assetManagerRole, setAssetManagerRole] = useState<`0x${string}` | undefined>("0x");
  const [assetManagerRoleCount, setAssetManagerRoleCount] = useState<number>(0);
  const [assetManagerRoleMembers, setAssetManagerRoleMembers] = useState<string[]>([]);

  const adminPrivateKey = process.env.NEXT_PUBLIC_ADMIN_PRIVATE_KEY || "";
  const provider = new ethers.JsonRpcProvider("http://localhost:8545");
  const adminSigner = new ethers.Wallet(adminPrivateKey, provider);

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
      if (!deployedContractAddress || !deployedContractAbi || !simpleUsdcContractData) {
        return;
      }

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

      setAdminRole(adminRoleData?.data);

      const adminRoleCountData = await refetchAdminRoleCount();

      setAdminRoleCount(Number(adminRoleCountData?.data));

      const operatorRoleData = await refetchOperatorRole();

      setOperatorRole(operatorRoleData?.data);

      const operatorRoleCountData = await refetchOperatorRoleCount();

      setOperatorRoleCount(Number(operatorRoleCountData?.data));

      const upgraderRoleData = await refetchUpgraderRole();

      setUpgraderRole(upgraderRoleData?.data);

      const upgraderRoleCountData = await refetchUpgraderRoleCount();

      setUpgraderRoleCount(Number(upgraderRoleCountData?.data));

      const assetManagerRoleData = await refetchAssetManagerRole();

      setAssetManagerRole(assetManagerRoleData?.data);

      const assetManagerRoleCountData = await refetchAssetManagerRoleCount();

      setAssetManagerRoleCount(Number(assetManagerRoleCountData?.data));

      if (adminSigner && adminRoleData && adminRoleCountData) {
        const _adminRoleMembers: string[] = [];
        const deployedContract = new ethers.Contract(deployedContractAddress, deployedContractAbi, adminSigner);

        for (let i = 0; i < Number(adminRoleCountData?.data); i++) {
          const adminRoleMember = await deployedContract.getRoleMember(adminRoleData?.data, BigInt(i));

          _adminRoleMembers.push(adminRoleMember);
        }

        setAdminRoleMembers(_adminRoleMembers);
      }
      setFetchingAdmins(false);

      if (adminSigner && operatorRoleData && operatorRoleCountData) {
        const _operatorRoleMembers: string[] = [];
        const deployedContract = new ethers.Contract(deployedContractAddress, deployedContractAbi, adminSigner);

        for (let i = 0; i < Number(operatorRoleCountData?.data); i++) {
          const operatorRoleMember = await deployedContract.getRoleMember(operatorRoleData?.data, BigInt(i));

          _operatorRoleMembers.push(operatorRoleMember);
        }

        setOperatorRoleMembers(_operatorRoleMembers);
      }
      setFetchingOperators(false);

      if (adminSigner && upgraderRoleData && upgraderRoleCountData) {
        const _upgraderRoleMembers: string[] = [];
        const deployedContract = new ethers.Contract(deployedContractAddress, deployedContractAbi, adminSigner);

        for (let i = 0; i < Number(upgraderRoleCountData?.data); i++) {
          const upgraderRoleMember = await deployedContract.getRoleMember(upgraderRoleData?.data, BigInt(i));

          _upgraderRoleMembers.push(upgraderRoleMember);
        }

        setUpgraderRoleMembers(_upgraderRoleMembers);
      }
      setFetchingUpgraders(false);

      if (adminSigner && assetManagerRoleData && assetManagerRoleCountData) {
        const _assetManagerRoleMembers: string[] = [];
        const deployedContract = new ethers.Contract(deployedContractAddress, deployedContractAbi, adminSigner);

        for (let i = 0; i < Number(assetManagerRoleCountData?.data); i++) {
          const assetManagerRoleMember = await deployedContract.getRoleMember(assetManagerRoleData?.data, BigInt(i));

          _assetManagerRoleMembers.push(assetManagerRoleMember);
        }

        setAssetManagerRoleMembers(_assetManagerRoleMembers);
      }
      setFetchingAssetManagers(false);
    };

    fetchData();
  }, [deployedContractAddress, simpleUsdcContractData, vaultBalance, custodianBalance, ...dependencies]);

  return {
    vaultBalance,
    custodianBalance,
    adminRoleCount,
    adminRoleMembers,
    operatorRoleCount,
    operatorRoleMembers,
    upgraderRoleCount,
    upgraderRoleMembers,
    assetManagerRoleCount,
    assetManagerRoleMembers,
    fetchingAdmins,
    fetchingOperators,
    fetchingUpgraders,
    fetchingAssetManagers,
  };
};
