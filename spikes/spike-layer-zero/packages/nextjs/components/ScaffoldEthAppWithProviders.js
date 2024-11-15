"use strict";
"use client";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ScaffoldEthAppWithProviders = exports.queryClient = void 0;
const react_1 = require("react");
const rainbowkit_1 = require("@rainbow-me/rainbowkit");
const react_query_1 = require("@tanstack/react-query");
const next_themes_1 = require("next-themes");
const react_hot_toast_1 = require("react-hot-toast");
const wagmi_1 = require("wagmi");
const Footer_1 = require("~~/components/Footer");
const Header_1 = require("~~/components/Header");
const scaffold_eth_1 = require("~~/components/scaffold-eth");
const ProgressBar_1 = require("~~/components/scaffold-eth/ProgressBar");
const scaffold_eth_2 = require("~~/hooks/scaffold-eth");
const wagmiConfig_1 = require("~~/services/web3/wagmiConfig");
const ScaffoldEthApp = ({ children }) => {
    (0, scaffold_eth_2.useInitializeNativeCurrencyPrice)();
    return (<>
      <div className="flex flex-col min-h-screen">
        <Header_1.Header />
        <main className="relative flex flex-col flex-1">{children}</main>
        <Footer_1.Footer />
      </div>
      <react_hot_toast_1.Toaster />
    </>);
};
exports.queryClient = new react_query_1.QueryClient({
    defaultOptions: {
        queries: {
            refetchOnWindowFocus: false,
        },
    },
});
const ScaffoldEthAppWithProviders = ({ children }) => {
    const { resolvedTheme } = (0, next_themes_1.useTheme)();
    const isDarkMode = resolvedTheme === "dark";
    const [mounted, setMounted] = (0, react_1.useState)(false);
    (0, react_1.useEffect)(() => {
        setMounted(true);
    }, []);
    return (<wagmi_1.WagmiProvider config={wagmiConfig_1.wagmiConfig}>
      <react_query_1.QueryClientProvider client={exports.queryClient}>
        <ProgressBar_1.ProgressBar />
        <rainbowkit_1.RainbowKitProvider avatar={scaffold_eth_1.BlockieAvatar} theme={mounted ? (isDarkMode ? (0, rainbowkit_1.darkTheme)() : (0, rainbowkit_1.lightTheme)()) : (0, rainbowkit_1.lightTheme)()}>
          <ScaffoldEthApp>{children}</ScaffoldEthApp>
        </rainbowkit_1.RainbowKitProvider>
      </react_query_1.QueryClientProvider>
    </wagmi_1.WagmiProvider>);
};
exports.ScaffoldEthAppWithProviders = ScaffoldEthAppWithProviders;
