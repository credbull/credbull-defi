'use client';
import { useEffect, useState } from 'react';

import { ContractName } from "~~/utils/scaffold-eth/contract";
import { getAllContracts } from "~~/utils/scaffold-eth/contractsData";
import { useAccount, useWaitForTransactionReceipt, useWriteContract } from "wagmi";
import { useDeployedContractInfo, useNetworkColor } from "~~/hooks/scaffold-eth";
import { useTargetNetwork } from "~~/hooks/scaffold-eth/useTargetNetwork";
import { useReadContract } from "wagmi";
import { set } from 'nprogress';


const selectedContractStorageKey = "scaffoldEth2.selectedContract";
const contractsData = getAllContracts();
const contractNames = Object.keys(contractsData) as ContractName[];



const ViewSection = (props: any) => {


    const [userData, setUserData] = useState<Number>(0);
    const [timePeriodsElapsed, setTimePeriodsElapsed] = useState<BigInt>(0n);
    const [interestEarned, setInterestEarned] = useState<BigInt>(0n);

    const { refetch: userReserveRefetch } = useReadContract({
        address: props.data.deployedContractData.address,
        functionName: 'userReserve',
        abi: props.data.deployedContractData.abi,
        args: [props.data.address, 0],
    });

    const { refetch: getCurrentTimePeriodsElapsedRefetch } = useReadContract({
        address: props.data.deployedContractData.address,
        functionName: 'getCurrentTimePeriodsElapsed',
        abi: props.data.deployedContractData.abi,
        args: [],
    });

    const  { refetch: getInterestEarnedRefetch } = useReadContract({
        address: props.data.deployedContractData.address,
        functionName: 'totalInterestEarned',
        abi: props.data.deployedContractData.abi,
        args: [props.data.address],
    });

    
    useEffect(() => {   
        console.log('props', props);

        if(userData === 0)
          userReserveRefetch().then((data) => {
            setUserData(Number(Number(data.data) / 10 ** 6));
          });

        if(timePeriodsElapsed === 0n) {
          getCurrentTimePeriodsElapsedRefetch().then((data) => {
            console.log('getCurrentTimePeriodsElapsed', data.data);
            setTimePeriodsElapsed(data.data as BigInt);
          });
        }

        if(interestEarned === 0n) {
          getInterestEarnedRefetch().then((data) => {
            setInterestEarned(data.data as BigInt);
          });
        }
    }, []);

    useEffect(() => {
      console.log('userData', userData);
      console.log('timePeriodsElapsed', timePeriodsElapsed);
    }, [timePeriodsElapsed, userData]);

    return <>
        <div className='view-section'>
            <p>Contract Address: {props.data.deployedContractData.address}</p>
            <p>Time period elapsed: {(timePeriodsElapsed).toString()} </p>
            <p> Principal amount: {(userData).toString()} USDC</p>
            <p> Interest earned: {(interestEarned).toString()} USDC</p>
        </div>
    </>
}



const Card = () => {
    const [amount, setAmount] = useState('');
    const { address } = useAccount();
    const { targetNetwork } = useTargetNetwork();
    console.log(contractsData);
    const { data: deployedContractDataUSDC, isLoading: deployedContractLoadingUSDC } = useDeployedContractInfo(contractNames[0]);
    const { data: deployedContractData, isLoading: deployedContractLoading } = useDeployedContractInfo(contractNames[1]);


  const handleDeposit = () => {
    
  };

  if(deployedContractLoading || deployedContractLoadingUSDC) {
    return (
      <div className="mt-14">
        <span className="loading loading-spinner loading-lg"></span>
      </div>
    );
  }

  if(!deployedContractData || !deployedContractDataUSDC) {
    return (
      <p className="text-3xl mt-14">
        {`No contract found by the name of "${contractNames[1]}" or "${contractNames[0]}" on chain "${targetNetwork.name}"!`}
      </p>
    );
  }

  return (
    <div className='align-items-start border-2 rounded border-neutral-100 p-10'>
      <h3>Enter Amount</h3>
      <input
        type="number"
        value={amount}
        onChange={(e) => setAmount(e.target.value)}
        placeholder="Enter amount"
        style={{ padding: '10px', width: '100%', marginBottom: '10px' }}
      />
      <div className='mt-5'>
        <button onClick={handleDeposit} className='p-2 border rounded border-neutral-100 w-1/2'>
            Deposit
        </button>
        <button onClick={handleDeposit} className='p-2 border rounded border-neutral-100 w-1/2'>
            Redeem
        </button>
      </div>

        <ViewSection data={{deployedContractData: deployedContractData, address: address}} />
    </div>
  );
};

export default Card;