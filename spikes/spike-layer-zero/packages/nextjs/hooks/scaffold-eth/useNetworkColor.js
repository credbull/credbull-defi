"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.useNetworkColor = exports.DEFAULT_NETWORK_COLOR = void 0;
exports.getNetworkColor = getNetworkColor;
const useTargetNetwork_1 = require("./useTargetNetwork");
const next_themes_1 = require("next-themes");
exports.DEFAULT_NETWORK_COLOR = ["#666666", "#bbbbbb"];
function getNetworkColor(network, isDarkMode) {
    var _a;
    const colorConfig = (_a = network.color) !== null && _a !== void 0 ? _a : exports.DEFAULT_NETWORK_COLOR;
    return Array.isArray(colorConfig) ? (isDarkMode ? colorConfig[1] : colorConfig[0]) : colorConfig;
}
/**
 * Gets the color of the target network
 */
const useNetworkColor = () => {
    const { resolvedTheme } = (0, next_themes_1.useTheme)();
    const { targetNetwork } = (0, useTargetNetwork_1.useTargetNetwork)();
    const isDarkMode = resolvedTheme === "dark";
    return getNetworkColor(targetNetwork, isDarkMode);
};
exports.useNetworkColor = useNetworkColor;
