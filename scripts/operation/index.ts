import 'dotenv/config';

import './src/utils/ensure-env';

(async () => {
  const file = process.argv[2].replace('--', '');
  const { main } = (await import(`./src/${file}`)) as { main: () => void };
  main();
})();
