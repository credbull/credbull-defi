import local from './deployments/31337.json';

export const deployments = {local}

type ContractNames = keyof typeof deployments.local;
export const contractNames = (Object.keys(deployments.local) as ContractNames[]);

type ABIs = { [key in ContractNames]: typeof deployments.local[key]['abi'] };

// TODO: store abi in db / query abi per version
export const abis = contractNames.reduce((acc, key) => {
    acc[key] = deployments.local[key].abi;
    return acc;
}, {} as ABIs);
