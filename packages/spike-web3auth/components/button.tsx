import React from "react";

interface IbuttonText {
  buttonText: string;
  onClick: React.MouseEventHandler<HTMLButtonElement>;
}

const Button: React.FC<IbuttonText> = (params) => (
  <button
    onClick={params.onClick}
    style={{
      height: 30,
      minWidth: 200,
      backgroundColor: "#2549aa",
      borderRadius: 5,
      alignContent: "center",
      justifyContent: "center",
      margin: 10,
      wordWrap: 'break-word'
    }}
  >
    {params.buttonText}
  </button>
);

export default Button;
