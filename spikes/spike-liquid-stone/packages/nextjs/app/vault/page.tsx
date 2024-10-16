import ViewSection from "./_components/ViewSection";
import type { NextPage } from "next";
import { getMetadata } from "~~/utils/scaffold-eth/getMetadata";

export const metadata = getMetadata({
  title: "Vault Interface",
  description: "Test the vault functionality with a user-friendly interface",
});

const VaultInterface: NextPage = () => {
  return (
    <>
      <div className="main-container mt-8 p-2">
        <ViewSection />
      </div>
    </>
  );
};

export default VaultInterface;
