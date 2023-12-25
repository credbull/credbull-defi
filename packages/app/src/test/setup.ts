import { generateMock } from '@anatine/zod-mock';
import { vi } from 'vitest';

import { envVariables } from '@/utils/env';

const vars = generateMock(envVariables);

Object.keys(vars).forEach((key) => {
  vi.stubEnv(key, vars[key as keyof typeof vars]);
});
