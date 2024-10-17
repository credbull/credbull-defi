import ViewSection from "./_components/ViewSection";
import type { NextPage } from "next";
import { getMetadata } from "~~/utils/scaffold-eth/getMetadata";

export const metadata = getMetadata({
  title: "Admin | Operator",
  description: "Give admins, operators and asset managers the possibilities to perform operating actions",
});

const HelpersInterface: NextPage = () => {
  return (
    <>
      <ViewSection />
    </>
  );
};

export default HelpersInterface;
