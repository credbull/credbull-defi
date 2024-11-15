"use strict";
"use client";
Object.defineProperty(exports, "__esModule", { value: true });
exports.SwitchTheme = void 0;
const react_1 = require("react");
const next_themes_1 = require("next-themes");
const outline_1 = require("@heroicons/react/24/outline");
const SwitchTheme = ({ className }) => {
    const { setTheme, resolvedTheme } = (0, next_themes_1.useTheme)();
    const [mounted, setMounted] = (0, react_1.useState)(false);
    const isDarkMode = resolvedTheme === "dark";
    const handleToggle = () => {
        if (isDarkMode) {
            setTheme("light");
            return;
        }
        setTheme("dark");
    };
    (0, react_1.useEffect)(() => {
        setMounted(true);
    }, []);
    if (!mounted)
        return null;
    return (<div className={`flex space-x-2 h-8 items-center justify-center text-sm ${className}`}>
      <input id="theme-toggle" type="checkbox" className="toggle toggle-primary bg-primary hover:bg-primary border-primary" onChange={handleToggle} checked={isDarkMode}/>
      <label htmlFor="theme-toggle" className={`swap swap-rotate ${!isDarkMode ? "swap-active" : ""}`}>
        <outline_1.SunIcon className="swap-on h-5 w-5"/>
        <outline_1.MoonIcon className="swap-off h-5 w-5"/>
      </label>
    </div>);
};
exports.SwitchTheme = SwitchTheme;
