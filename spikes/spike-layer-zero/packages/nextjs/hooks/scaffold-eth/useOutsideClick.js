"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.useOutsideClick = void 0;
const react_1 = require("react");
/**
 * Handles clicks outside of passed ref element
 * @param ref - react ref of the element
 * @param callback - callback function to call when clicked outside
 */
const useOutsideClick = (ref, callback) => {
    (0, react_1.useEffect)(() => {
        function handleOutsideClick(event) {
            if (!(event.target instanceof Element)) {
                return;
            }
            if (ref.current && !ref.current.contains(event.target)) {
                callback();
            }
        }
        document.addEventListener("click", handleOutsideClick);
        return () => document.removeEventListener("click", handleOutsideClick);
    }, [ref, callback]);
};
exports.useOutsideClick = useOutsideClick;
