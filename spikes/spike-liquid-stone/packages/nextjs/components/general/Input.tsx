"use client";

import { useTheme } from "next-themes";

const Input = ({
  type,
  value,
  placeholder,
  className,
  disabled = false,
  onChangeHandler,
}: {
  type: string;
  value: string | number;
  placeholder: string;
  className?: string;
  disabled?: boolean;
  onChangeHandler: (e: string) => void;
}) => {
  const { resolvedTheme } = useTheme();

  return (
    <input
      type={type}
      value={value}
      placeholder={placeholder}
      className={
        className ||
        `border ${
          resolvedTheme === "dark" ? "border-gray-700 bg-gray-700 text-white" : "border-gray-300"
        } p-2 w-full mb-4 outline-none focus:ring-0`
      }
      disabled={disabled}
      onChange={e => onChangeHandler(e.target.value)}
    />
  );
};

export default Input;
