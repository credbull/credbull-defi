export const formatTimestamp = (timestamp: number) => {
  const date = new Date(Number(timestamp) * 1000);

  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, "0");
  const day = String(date.getDate()).padStart(2, "0");
  const hours = String(date.getHours()).padStart(2, "0");
  const minutes = String(date.getMinutes()).padStart(2, "0");
  const seconds = String(date.getSeconds()).padStart(2, "0");

  return `${year}-${month}-${day} ${hours}:${minutes}:${seconds}`;
};

export const formatAddress = (address: string, chars = 6) => {
  if (!address) return "";
  const start = address.slice(0, chars);
  const end = address.slice(-chars);
  return `${start}...${end}`;
};

export const formatNumber = (value: string | number | bigint) =>
  Number(value).toLocaleString("en-US", {
    minimumFractionDigits: value.toString().split(".")[1]?.length || 0,
  });

export function toStr(amount: bigint | number, decimals = 1000000) {
  const scaledDown = Number(amount) / decimals;
  return scaledDown.toLocaleString(undefined, {
    useGrouping: true,
    maximumFractionDigits: Math.floor(Math.log10(decimals)),
  });
}
