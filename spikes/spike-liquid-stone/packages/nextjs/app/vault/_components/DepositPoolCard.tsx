"use client";

import { useTheme } from "next-themes";
import ContractValueBadge from "~~/components/general/ContractValueBadge";
import { DepositPool } from "~~/types/vault";

const DepositPoolCard = ({ pool, onClickHandler }: { pool: DepositPool; onClickHandler?: (params: any) => void }) => {
  const { resolvedTheme } = useTheme();

  return (
    <div
      onClick={onClickHandler}
      className={`relative cursor-pointer overflow-hidden transition-transform transform-gpu hover:scale-105 duration-500 ease-in-out rounded-lg shadow-xl p-6 ${
        resolvedTheme === "dark" ? "bg-gray-800 text-white" : "bg-white text-black"
      } flex flex-wrap gap-4`}
      style={{
        borderRadius: "16px",
        boxShadow:
          resolvedTheme === "dark"
            ? "0 4px 12px rgba(255, 255, 255, 0.1), 0 6px 20px rgba(255, 255, 255, 0.1)"
            : "0 4px 12px rgba(0, 0, 0, 0.1), 0 6px 20px rgba(0, 0, 0, 0.1)",
        transformStyle: "preserve-3d",
      }}
    >
      <div className="absolute inset-0 bg-gradient-to-r from-indigo-500 via-purple-500 to-pink-500 opacity-30 blur-lg rounded-lg"></div>

      <ContractValueBadge name="Deposit period" value={Number(pool.depositId)} />
      <ContractValueBadge name="Balance" value={`${pool.balance} USDC`} />
      <ContractValueBadge name="Shares" value={pool.shares} />
      <ContractValueBadge name="Requested Amount" value={pool.unlockRequestAmount} />
      <ContractValueBadge name="Yield" value={`${pool.yield} USDC`} />

      <div
        className="absolute inset-0 transition-opacity duration-700 opacity-0 hover:opacity-100"
        style={{
          background: "radial-gradient(circle, rgba(255,255,255,0.1) 10%, transparent 80%)",
          pointerEvents: "none",
        }}
      ></div>
    </div>
  );
};

export default DepositPoolCard;
