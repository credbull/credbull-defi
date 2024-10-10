"use client";

const Button = ({
  text,
  size = "medium",
  bgColor = "black",
  textColor = "white",
  tooltipData = "",
  onClickHandler,
}: {
  text: string;
  size?: "small" | "medium" | "large";
  bgColor?: "black" | "yellow" | "blue" | "green";
  textColor?: "white";
  tooltipData?: string;
  onClickHandler: () => void;
}) => {
  const buttonConfig = {
    bg: {
      black: {
        bgColor: "bg-black-500",
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
      medium: "px-4 py-2 mr-2",
      large: "px-5 py-2",
    },
  };

  return (
    <button
      onClick={onClickHandler}
      data-tip={tooltipData}
      className={`tooltip tooltip-bottom tooltip-accent ${buttonConfig.bg[bgColor].bgColor} ${buttonConfig.text[textColor].color} ${buttonConfig.size[size]} rounded`}
    >
      {text}
    </button>
  );
};

export default Button;
