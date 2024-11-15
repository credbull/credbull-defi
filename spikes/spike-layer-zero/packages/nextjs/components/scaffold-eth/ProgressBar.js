"use strict";
"use client";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.ProgressBar = ProgressBar;
const react_1 = require("react");
const nprogress_1 = __importDefault(require("nprogress"));
function ProgressBar() {
    const height = "3px";
    const color = "#2299dd";
    const styles = (<style>
      {`
        #nprogress {
          pointer-events: none;
        }
        #nprogress .bar {
          background: ${color};
          position: fixed;
          z-index: 99999;
          top: 0;
          left: 0;
          width: 100%;
          height: ${typeof height === `string` ? height : `${height}px`};
        }
        /* Fancy blur effect */
        #nprogress .peg {
          display: block;
          position: absolute;
          right: 0px;
          width: 100px;
          height: 100%;
          box-shadow: 0 0 10px ${color}, 0 0 5px ${color};
          opacity: 1.0;
          -webkit-transform: rotate(3deg) translate(0px, -4px);
              -ms-transform: rotate(3deg) translate(0px, -4px);
                  transform: rotate(3deg) translate(0px, -4px);
        }
    `}
    </style>);
    (0, react_1.useEffect)(() => {
        nprogress_1.default.configure({ showSpinner: false });
        const handleAnchorClick = (event) => {
            const anchor = event.currentTarget;
            const targetUrl = anchor.href;
            const currentUrl = location.href;
            const isTargetBlank = (anchor === null || anchor === void 0 ? void 0 : anchor.target) === "_blank";
            if (targetUrl === currentUrl || isTargetBlank)
                return;
            nprogress_1.default.start();
        };
        const handleMutation = () => {
            const anchorElements = document.querySelectorAll("a");
            anchorElements.forEach(anchor => anchor.addEventListener("click", handleAnchorClick));
        };
        const mutationObserver = new MutationObserver(handleMutation);
        mutationObserver.observe(document, { childList: true, subtree: true });
        window.history.pushState = new Proxy(window.history.pushState, {
            apply: (target, thisArg, argArray) => {
                nprogress_1.default.done();
                return target.apply(thisArg, argArray);
            },
        });
    });
    return styles;
}
