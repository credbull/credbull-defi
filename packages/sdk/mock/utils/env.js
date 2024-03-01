'use strict';
Object.defineProperty(exports, '__esModule', { value: true });
exports.envVariables = void 0;
const zod_1 = require('zod');
exports.envVariables = zod_1.z.object({
  ADMIN_PRIVATE_KEY: zod_1.z.string(),
});
