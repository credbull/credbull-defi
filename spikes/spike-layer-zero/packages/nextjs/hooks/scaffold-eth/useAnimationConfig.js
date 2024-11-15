"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.useAnimationConfig = useAnimationConfig;
const react_1 = require("react");
const ANIMATION_TIME = 2000;
function useAnimationConfig(data) {
    const [showAnimation, setShowAnimation] = (0, react_1.useState)(false);
    const [prevData, setPrevData] = (0, react_1.useState)();
    (0, react_1.useEffect)(() => {
        if (prevData !== undefined && prevData !== data) {
            setShowAnimation(true);
            setTimeout(() => setShowAnimation(false), ANIMATION_TIME);
        }
        setPrevData(data);
    }, [data, prevData]);
    return {
        showAnimation,
    };
}
