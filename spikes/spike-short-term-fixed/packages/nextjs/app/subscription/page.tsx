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
      <div className="mt-8 bg-secondary p-10">
        <h1 className="text-4xl my-0">Short term Contracts</h1>
        <p className="text-neutral">
          You can debug & interact with your deployed short term contracts here.
          <br /> Check{" "}
          <code className="italic bg-base-300 text-base font-bold [word-spacing:-0.5rem] px-1">
            Hello world!
          </code>{" "}
        </p>
      </div>
      <div className="container max-w-full">
        <div className="columns-2 align-items-start mt-6">
          <div className="p-10">
            <h2> Short term fixed yield - 30 days </h2>
            <Card />
          </div>
          <div className="p-10">
            <h2> Short term fixed yield - 90 days </h2>
            <Card />
          </div>
        </div>
      </div>
    </>
  );
};

export default ShortTerm;
