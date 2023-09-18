const ZeroAddress: string = "0x0000000000000000000000000000000000000000"; // native token address

export function paramsToSign(
    moduleAddress: string,
    chainId: bigint,
    {
        safe,
        token,
        to,
        amount,
    }: {
        safe: string
        token: string
        to: string
        amount: number | bigint
    },
    nonce: bigint
) {
    const domain = {chainId, verifyingContract: moduleAddress}
    const primaryType = 'AllowanceTransfer'
    const types = {
        AllowanceTransfer: [
            {type: 'address', name: 'safe'},
            {type: 'address', name: 'token'},
            {type: 'address', name: 'to'},
            {type: 'uint96', name: 'amount'},
            {type: 'address', name: 'paymentToken'},
            {type: 'uint96', name: 'payment'},
            {type: 'uint16', name: 'nonce'},
        ],
    }
    const message = {
        safe,
        token,
        to,
        amount,
        paymentToken: ZeroAddress,
        payment: 0,
        nonce,
    }

    return {domain, primaryType, types, message}
}