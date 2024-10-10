"use client";

import { useTheme } from "next-themes";

const ActionLogSection = ({ log }: { log: [string] }) => {
  const { resolvedTheme } = useTheme();

  return (
    <div
      className={`mt-8 ${resolvedTheme === "dark" ? "bg-gray-800 text-white" : "bg-white text-black"} p-4 rounded-lg`}
    >
      <h2 className="text-xl font-bold mb-4">Activity Log</h2>
      <ul>
        {log.map((entry, index) => (
          <li key={index} className={`${resolvedTheme === "dark" ? "bg-gray-700" : "bg-gray-200"} p-2 mb-2 rounded`}>
            {entry}
          </li>
        ))}
      </ul>
    </div>
  );
};

export default ActionLogSection;
