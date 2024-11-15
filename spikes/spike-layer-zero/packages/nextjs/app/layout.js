"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.metadata = void 0;
require("@rainbow-me/rainbowkit/styles.css");
const ScaffoldEthAppWithProviders_1 = require("~~/components/ScaffoldEthAppWithProviders");
const ThemeProvider_1 = require("~~/components/ThemeProvider");
require("~~/styles/globals.css");
const getMetadata_1 = require("~~/utils/scaffold-eth/getMetadata");
exports.metadata = (0, getMetadata_1.getMetadata)({
    title: "Scaffold-ETH 2 App",
    description: "Built with 🏗 Scaffold-ETH 2",
});
const ScaffoldEthApp = ({ children }) => {
    return (<html suppressHydrationWarning>
      <body>
        <ThemeProvider_1.ThemeProvider enableSystem>
          <ScaffoldEthAppWithProviders_1.ScaffoldEthAppWithProviders>{children}</ScaffoldEthAppWithProviders_1.ScaffoldEthAppWithProviders>
        </ThemeProvider_1.ThemeProvider>
      </body>
    </html>);
};
exports.default = ScaffoldEthApp;
