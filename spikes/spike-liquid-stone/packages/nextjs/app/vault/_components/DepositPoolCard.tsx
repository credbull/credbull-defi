"use client";

import { useTheme } from "next-themes";
import { DepositPool } from "~~/types/vault";

const DepositPoolCard = ({
  pool,
  onClickHandler,
}: {
  pool: DepositPool;
  onClickHandler: (pool: DepositPool) => void;
}) => {
  const { resolvedTheme } = useTheme();

  return (
    <div
      onClick={() => onClickHandler(pool)}
      className={`relative cursor-pointer overflow-hidden transition-transform transform-gpu hover:scale-105 duration-500 ease-in-out rounded-lg shadow-xl p-6 ${
        resolvedTheme === "dark" ? "bg-gray-800 text-white" : "bg-white text-black"
      }`}
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

      <p className="relative z-10 text-center">Deposit period: {Number(pool.depositId)}</p>
      <p className="relative z-10 text-center">Balance: {pool.balance} USDC</p>
      <p className="relative z-10 text-center">Shares: {pool.shares}</p>
      <p className="relative z-10 text-center">Requested Amount: {pool.unlockRequestAmount}</p>
      <p className="relative z-10 text-center">Yield: {pool.yield} USDC</p>

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
