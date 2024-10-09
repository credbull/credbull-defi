"use client";

import { ReactNode } from "react";
import { useTheme } from "next-themes";

const ActionCard = ({ children }: { children: ReactNode }) => {
  const { resolvedTheme } = useTheme();

  return (
    <div
      className={`${
        resolvedTheme === "dark" ? "bg-gray-800 text-white" : "bg-white text-black"
      } shadow-md p-4 rounded-lg`}
    >
      {children}
    </div>
  );
};

export default ActionCard;
