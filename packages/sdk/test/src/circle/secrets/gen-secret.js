/* eslint-disable @typescript-eslint/no-var-requires */
const crypto = require('crypto');
/* eslint-enable @typescript-eslint/no-var-requires */

const secret = crypto.randomBytes(32).toString('hex');

console.log(secret);
