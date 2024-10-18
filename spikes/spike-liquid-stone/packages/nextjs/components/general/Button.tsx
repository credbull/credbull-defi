"use client";

import LoadingSpinner from "./LoadingSpinner";

const Button = ({
  text,
  size = "medium",
  bgColor = "black",
  textColor = "white",
  tooltipData = "",
  flex = "",
  disabled = false,
  loading = false,
  onClickHandler,
}: {
  text: string;
  size?: "small" | "medium" | "large";
  bgColor?: "black" | "gray" | "yellow" | "blue" | "green";
  textColor?: "white";
  tooltipData?: string;
  flex?: string;
  disabled?: boolean;
  loading?: boolean;
  onClickHandler: () => void;
}) => {
  const buttonConfig = {
    bg: {
      black: {
        bgColor: "bg-black-500",
        color: "text-white",
      },
      gray: {
        bgColor: "bg-gray-500",
        color: "text-white",
      },
      yellow: {
        bgColor: "bg-yellow-500",
        color: "text-white",
      },
      blue: {
        bgColor: "bg-blue-500",
        color: "text-white",
      },
      green: {
        bgColor: "bg-green-500",
        color: "text-white",
      },
    },
    text: {
      white: {
        color: "text-white",
      },
    },
    size: {
      small: "px-3 py-2",
      medium: "px-4 py-2",
      large: "px-5 py-2",
    },
  };

  return (
    <button
      onClick={onClickHandler}
      data-tip={loading ? "Data loading.." : tooltipData}
      disabled={disabled}
      className={`${flex} tooltip tooltip-bottom tooltip-accent ${buttonConfig.bg[bgColor].bgColor} ${buttonConfig.text[textColor].color} ${buttonConfig.size[size]} rounded`}
    >
      {/* {text} */}
      {loading ? <LoadingSpinner size="small" /> : text}
    </button>
  );
};

export default Button;
