export const fromDecimals = (value: number | bigint, decimals = 6): number => {
  return Number(value) / 10 ** decimals;
};

export const toDecimals = (value: number, decimals = 6): bigint => {
  return BigInt(value * 10 ** decimals);
};

export const formatNumber = (value: number, decimalPlaces = 2): string => {
  return value.toFixed(decimalPlaces);
};
