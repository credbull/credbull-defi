const path = require("path");
const fs = require("fs");

async function exportAbi() {
  const folderPath = path.resolve(__dirname, "../../broadcast");
  const outputPath = path.resolve(__dirname, "../../deployments");
  const foundryOutPath = path.resolve(__dirname, "../../out");

  const deployFiles = await fs.promises.readdir(folderPath);
  for (const deployFile of deployFiles) {
    const chainFiles = await fs.promises.readdir(
      path.resolve(folderPath, deployFile)
    );

    for (const chainFile of chainFiles) {
      const runFiles = await fs.promises.readdir(
        path.resolve(folderPath, deployFile, chainFile)
      );

      let outputObj = {};
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

              const contractBuffer = fs.readFileSync(
                path.resolve(
                  foundryOutPath,
                  `${contractName}.sol`,
                  `${contractName}.json`
                )
              );
              const output = JSON.parse(contractBuffer.toString("utf-8"));

              const isNewContract = !outputObj[contractName];
              const prop = isNewContract
                ? contractName
                : `${contractName}_${contractAddress}`;

              outputObj[prop] = {
                address: contractAddress,
                abi: output.abi,
              };
            }
          }
        }
      }
      if (!fs.existsSync(outputPath)) {
        fs.mkdirSync(outputPath, { recursive: true });
      }

      fs.writeFileSync(
        path.resolve(outputPath, `${chainFile}.json`),
        JSON.stringify(outputObj)
      );
    }
  }
}

(async () => await exportAbi())();
