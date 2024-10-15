import { useEffect, useState } from "react";
import { ContractAbi } from "~~/utils/scaffold-eth/contract";
import { UnlockRequest } from "~~/types/async";
import { ethers } from "ethers";

export const useFetchUnlockRequests = ({
    address,
    deployedContractAddress,
    deployedContractAbi,
    currentPeriod,
    noticePeriod,
    refetch,
}: {
    address: string;
    deployedContractAddress: string;
    deployedContractAbi: ContractAbi;
    currentPeriod: number;
    noticePeriod: number;
    refetch: any;   
}) => {
    const [unlockRequests, setUnlockRequests] = useState<UnlockRequest[]>([]);

    useEffect(() => {
        async function getUnlockRequests() {
            if (!address || !deployedContractAddress || !noticePeriod) return;
            
            const provider = new ethers.JsonRpcProvider("http://127.0.0.1:8545");
            const contract = new ethers.Contract(deployedContractAddress, deployedContractAbi, provider);
            const requests: UnlockRequest[] = [];

            for (let i = 0; i <= currentPeriod + noticePeriod; i ++) {
                const unlock = await contract.unlockRequestAmount(address, BigInt(i));

                const unlockAmount = BigInt(unlock || 0);

                if(unlockAmount > 0) {
                    const unlockRequest: UnlockRequest = {requestId: i, unlockAmount: unlockAmount};
                    requests.push(unlockRequest);
                }
            }
            setUnlockRequests(requests);
        }

        getUnlockRequests();
    }, [address, deployedContractAddress, deployedContractAbi, currentPeriod, noticePeriod, refetch]);

    return { unlockRequests };
}