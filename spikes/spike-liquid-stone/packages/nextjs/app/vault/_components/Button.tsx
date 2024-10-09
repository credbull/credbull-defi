"use client";

const Button = ({
  text,
  size = "500",
  bgColor = "black",
  textColor = "white",
  onClickHandler,
}: {
  text: string;
  size?: string;
  bgColor?: string;
  textColor?: string;
  onClickHandler: () => void;
}) => {
  return (
    <button onClick={onClickHandler} className={`bg-${bgColor}-${size} text-${textColor} px-4 py-2 rounded`}>
      {text}
    </button>
  );
};

export default Button;
