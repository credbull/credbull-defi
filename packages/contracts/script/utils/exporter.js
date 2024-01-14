const path = require("path");
const fs = require("fs");

async function exportAbi() {
  const folderPath = path.resolve(__dirname, "../../broadcast");
  const outputPath = path.resolve(__dirname, "../../deployments");

  const deployFiles = await fs.promises.readdir(folderPath);
  for (const deployFile of deployFiles) {
    const chainFiles = await fs.promises.readdir(
      path.resolve(folderPath, deployFile)
    );

    for (const chainFile of chainFiles) {
      const runFiles = await fs.promises.readdir(
        path.resolve(folderPath, deployFile, chainFile)
      );

      let addresses = {};
      for (const runFile of runFiles) {
        if (runFile.includes("latest")) {
          const runBuffer = fs.readFileSync(
            path.resolve(folderPath, deployFile, chainFile, runFile)
          );
          const output = JSON.parse(runBuffer.toString("utf-8"));

          const transactions = output["transactions"];
          for (const tx of transactions) {
            if (tx["transactionType"] === "CREATE") {
              const contractName = tx["contractName"];
              const contractAddress = tx["contractAddress"];

              addresses[contractName] = (addresses[contractName] || []).concat(
                contractAddress
              );
            }
          }
        }
      }
      if (!fs.existsSync(outputPath)) {
        fs.mkdirSync(outputPath, { recursive: true });
      }

      fs.writeFileSync(
        path.resolve(outputPath, `${chainFile}.json`),
        JSON.stringify(addresses)
      );
    }
    console.log(`Finished exporting addresses`);
  }
}

(async () => await exportAbi())();
