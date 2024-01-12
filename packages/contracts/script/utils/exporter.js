const path = require('path');
const fs = require('fs');

async function exportAbi() {
    const folderPath = path.resolve(__dirname, "../../broadcast");
    const outputPath = path.resolve(__dirname, "../../deployments");
    const foundryOutPath = path.resolve(__dirname, "../../out");
    const deployFiles = await fs.promises.readdir(folderPath);

    for(const deployFile of deployFiles) {
        const chainFiles = await fs.promises.readdir(folderPath + "/" + deployFile);
        for(const chainFile of chainFiles) {
            const runFiles = await fs.promises.readdir(folderPath + "/" + deployFile + '/' + chainFile);

            let outputObj = {}

            for(const runFile of runFiles) {
                if(runFile.includes('latest')) {
                    const output = JSON.parse(fs.readFileSync(folderPath + "/" + deployFile + '/' + chainFile + '/' + runFile));

                    const transactions = output['transactions'];

                    transactions.forEach((tx) => {
                        if(tx['transactionType'] == 'CREATE') {
                            const contractName = tx['contractName'];
                            
                            const output = JSON.parse(fs.readFileSync(foundryOutPath + "/" + contractName + '.sol/' + contractName + '.json'));

                            outputObj[contractName] = {
                                address: tx['contractAddress'],
                                abi: output.abi
                            }
                        }
                    });
                }
            }
            if (!fs.existsSync(outputPath)){
                fs.mkdirSync(outputPath, { recursive: true });
            }
            fs.writeFileSync(outputPath + "/" + chainFile + '.json', JSON.stringify(outputObj));
        }
    }
}

exportAbi();