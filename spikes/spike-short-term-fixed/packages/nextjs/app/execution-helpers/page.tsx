import Card from "./_components/Card";
import type { NextPage } from "next";
import { getMetadata } from "~~/utils/scaffold-eth/getMetadata";

export const metadata = getMetadata({
  title: "Short term yield",
  description: "Short term yield",
});

const ShortTerm: NextPage = () => {
  return (
    <>
      <div className="main-container mt-8 p-10">
        <h1 className="text-2xl"> Execution helpers </h1>
        <Card />
      </div>
    </>
  );
};

export default ShortTerm;
