"use client";

import { useTheme } from "next-themes";

const ContractValueBadge = ({
  name,
  value,
  onClickHandler,
}: {
  name: string;
  value: any;
  onClickHandler?: (params: any) => void;
}) => {
  const { resolvedTheme } = useTheme();

  return (
    <span
      className={`relative cursor-pointer transition-transform transform-gpu hover:scale-105 duration-500 ease-in-out px-3 py-1 rounded-full shadow-lg ${
        resolvedTheme === "dark" ? "bg-gray-700 text-white" : "bg-gray-200 text-black"
      }`}
      onClick={onClickHandler}
    >
      {name}: {value}
      <div
        className="absolute inset-0 transition-opacity duration-700 opacity-0 hover:opacity-100"
        style={{
          background: "radial-gradient(circle, rgba(255,255,255,0.1) 10%, transparent 80%)",
          pointerEvents: "none",
        }}
      ></div>
    </span>
  );
};

export default ContractValueBadge;
