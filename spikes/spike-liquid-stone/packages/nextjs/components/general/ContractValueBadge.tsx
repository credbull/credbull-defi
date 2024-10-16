"use client";

import { useTheme } from "next-themes";

const ContractValueBadge = ({
  name,
  value,
  theme = "gray",
  onClickHandler,
}: {
  name?: string;
  value: any;
  theme?: "gray" | "red";
  onClickHandler?: (params: any) => void;
}) => {
  const { resolvedTheme } = useTheme();

  const badgeConfig = {
    theme: {
      gray: {
        dark: "bg-gray-700 text-white",
        light: "bg-gray-200 text-black",
      },
      red: {
        dark: "bg-red-700 text-white",
        light: "bg-red-200 text-black",
      },
    },
  };

  return (
    <span
      className={`relative cursor-pointer transition-transform transform-gpu hover:scale-105 duration-500 ease-in-out px-3 py-1 rounded-full shadow-lg ${
        resolvedTheme === "dark" ? badgeConfig.theme[theme].dark : badgeConfig.theme[theme].light
      }`}
      onClick={onClickHandler}
    >
      {name ? `${name} :` : ""} {value}
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
