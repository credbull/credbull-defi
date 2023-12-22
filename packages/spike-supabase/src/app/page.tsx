import Image from "next/image";
import Button from "./components/Button/Button";
import { useRouter } from "next/navigation";
import Link from "next/link";

export default function Home() {
  // const router = useRouter();

  const handleNavigate = () => {
    // Use the router to navigate to another page
    // router.push("/samplepage1");
    console.log("hai");
    // return <Link href="/SamplePage1">Dashboard</Link>;
  };

  return (
    <main className="flex min-h-screen flex-col items-center justify-between p-24">
      {/* <Button
          buttonText="EmailPassword"
          onClick={handleNavigate}
        ></Button> */}

      <Link href="/EmailPassword">
        <div
          style={{
            height: 50,
            width: 200,
            backgroundColor: "red",
            justifyContent: "center",
            alignItems: "center",
            display: "flex",
          }}
        >
          EmailPassword
        </div>
      </Link>
    </main>
  );
}
