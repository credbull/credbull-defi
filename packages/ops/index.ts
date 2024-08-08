(async () => {
  const file = process.argv[2].replace('--', '');

  console.log(process.argv);

  const scenarios = process.argv[3]
    ? process.argv[3].split(',').reduce((acc, cur) => {
        return { ...acc, [cur]: true };
      }, {})
    : {};

  const params = process.argv[4]
    ? process.argv[4].split(',').reduce((acc, cur) => {
        const [key, value] = cur.split(':');
        return { ...acc, [key]: value };
      }, {})
    : {};

  const { main } = (await import(`./src/${file}`)) as { main: (opt: typeof scenarios, args?: typeof params) => void };
  main(scenarios, params);
})();
