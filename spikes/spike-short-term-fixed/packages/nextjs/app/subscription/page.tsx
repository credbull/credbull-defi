import type { NextPage } from "next";
import { getMetadata } from "~~/utils/scaffold-eth/getMetadata";
import Card from "./_components/Card";

export const metadata = getMetadata({
  title: "Short term yield",
  description: "Short term yield",
});


const ShortTerm: NextPage = () => {
  return (
    <>
        <div className="mt- 8 p-10">
          <h1 className="text-2xl"> Short term fixed yield - 30 days </h1>
          <Card />
        </div>
    </>
  );
};

export default ShortTerm;
