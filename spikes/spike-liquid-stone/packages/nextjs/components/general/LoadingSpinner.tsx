"use client";

const LoadingSpinner = ({
  size = "large",
  textColor = "white",
}: {
  size?: "small" | "medium" | "large";
  textColor?: "white" | "black";
}) => {
  const loadingSpinnerConfig = {
    text: {
      white: {
        color: "text-white",
      },
      black: {
        color: "text-black",
      },
    },
    size: {
      small: "loading-sm",
      medium: "loading-md",
      large: "loading-lg",
    },
  };

  return (
    <div className="flex justify-center items-center flex-1">
      <span
        className={`loading loading-spinner ${loadingSpinnerConfig.size[size]} ${loadingSpinnerConfig.text[textColor].color}`}
      ></span>
    </div>
  );
};

export default LoadingSpinner;
