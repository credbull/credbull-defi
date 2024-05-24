const { generatePublicPrivateKeyPair } = require("@primevault/js-api-sdk");

generatePublicPrivateKeyPair().then((response) => {
  console.log(response);
})