import 'dotenv/config';

import './src/utils/ensure-env';

(async () => {
  const { main } = await import('./src/main');
  main();
})();
