require('dotenv').config();

const path = require('path');
const fs = require('fs');

async function exportAddress() {
  const contracts = {};

  const folderPath = path.resolve(__dirname, '../../broadcast');
  const outputPath = path.resolve(__dirname, '../../deployments/');
  const outputFileName = path.resolve(__dirname, '../../deployments/index.json');

  const deployFiles = await fs.promises.readdir(folderPath);
  for (const deployFile of deployFiles) {
    const deployFilePath = path.resolve(folderPath, deployFile);
    const chainFiles = await fs.promises.readdir(deployFilePath);

    for (const chainFile of chainFiles) {
      contracts[chainFile] = contracts[chainFile] || {};
      const runBuffer = fs.readFileSync(path.resolve(deployFilePath, chainFile, 'run-latest.json'));

      const output = JSON.parse(runBuffer.toString('utf-8'));
      const transactions = output['transactions'];
      for (const tx of transactions) {
        if (tx['transactionType'] === 'CREATE') {
          const contractName = tx['contractName'];

          contracts[chainFile][contractName] = (contracts[chainFile][contractName] || []).concat({
            name: contractName,
            address: tx['contractAddress'],
            arguments: tx['arguments'],
          });
        }
      }
    }
    if (!fs.existsSync(outputPath)) {
      fs.mkdirSync(outputPath, { recursive: true });
    }

    fs.writeFileSync(path.resolve(outputFileName), JSON.stringify(contracts));
  }
  return contracts;
}

(async () => {
  try {
    await exportAddress();
  } catch (e) {
    console.log(e);
  } finally {
    console.log(`Finished exporting contracts`);
  }
})();
