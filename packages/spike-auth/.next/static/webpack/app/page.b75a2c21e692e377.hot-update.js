"use strict";
/*
 * ATTENTION: An "eval-source-map" devtool has been used.
 * This devtool is neither made for production nor for readable output files.
 * It uses "eval()" calls to create a separate source file with attached SourceMaps in the browser devtools.
 * If you are trying to read the output file, select a different devtool (https://webpack.js.org/configuration/devtool/)
 * or disable the default devtool with "devtool: false".
 * If you are looking for production-ready output files, see mode: "production" (https://webpack.js.org/configuration/mode/).
 */
self["webpackHotUpdate_N_E"]("app/page",{

/***/ "(app-client)/./app/page.tsx":
/*!**********************!*\
  !*** ./app/page.tsx ***!
  \**********************/
/***/ (function(module, __webpack_exports__, __webpack_require__) {

eval(__webpack_require__.ts("__webpack_require__.r(__webpack_exports__);\n/* harmony import */ var react_jsx_dev_runtime__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! react/jsx-dev-runtime */ \"(app-client)/./node_modules/next/dist/compiled/react/jsx-dev-runtime.js\");\n/* harmony import */ var react__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! react */ \"(app-client)/./node_modules/next/dist/compiled/react/index.js\");\n/* harmony import */ var react__WEBPACK_IMPORTED_MODULE_1___default = /*#__PURE__*/__webpack_require__.n(react__WEBPACK_IMPORTED_MODULE_1__);\n/* harmony import */ var _web3auth_modal__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(/*! @web3auth/modal */ \"(app-client)/./node_modules/@web3auth/modal/dist/modal.esm.js\");\n/* harmony import */ var _web3auth_base__WEBPACK_IMPORTED_MODULE_3__ = __webpack_require__(/*! @web3auth/base */ \"(app-client)/./node_modules/@web3auth/base/dist/base.esm.js\");\n/* harmony import */ var web3__WEBPACK_IMPORTED_MODULE_4__ = __webpack_require__(/*! web3 */ \"(app-client)/./node_modules/web3/lib/esm/index.js\");\n/* provided dependency */ var process = __webpack_require__(/*! process */ \"(app-client)/./node_modules/process/browser.js\");\n/* eslint-disable @typescript-eslint/no-use-before-define */ /* eslint-disable no-console */ /* eslint-disable @typescript-eslint/no-shadow */ /* __next_internal_client_entry_do_not_use__ default auto */ \nvar _s = $RefreshSig$();\n// IMP START - Quick Start\n\n// IMP END - Quick Start\n\n\n\n// IMP START - SDK Initialization\n// IMP START - Dashboard Registration\nconst clientId = process.env.WEB3AUTH_CLIENT_ID // get from https://dashboard.web3auth.io\n;\n// IMP END - Dashboard Registration\nconst chainConfig = {\n    chainNamespace: _web3auth_base__WEBPACK_IMPORTED_MODULE_3__.CHAIN_NAMESPACES.EIP155,\n    chainId: \"0x1\",\n    rpcTarget: \"https://rpc.ankr.com/eth\",\n    displayName: \"Ethereum Mainnet\",\n    blockExplorer: \"https://etherscan.io/\",\n    ticker: \"ETH\",\n    tickerName: \"Ethereum\"\n};\nconst web3auth = new _web3auth_modal__WEBPACK_IMPORTED_MODULE_2__.Web3Auth({\n    clientId,\n    chainConfig,\n    web3AuthNetwork: \"sapphire_devnet\"\n});\n// IMP END - SDK Initialization\nfunction App() {\n    _s();\n    const [provider, setProvider] = (0,react__WEBPACK_IMPORTED_MODULE_1__.useState)(null);\n    const [loggedIn, setLoggedIn] = (0,react__WEBPACK_IMPORTED_MODULE_1__.useState)(false);\n    (0,react__WEBPACK_IMPORTED_MODULE_1__.useEffect)(()=>{\n        const init = async ()=>{\n            try {\n                // IMP START - SDK Initialization\n                await web3auth.initModal();\n                // IMP END - SDK Initialization\n                setProvider(web3auth.provider);\n                if (web3auth.connected) {\n                    setLoggedIn(true);\n                }\n            } catch (error) {\n                console.error(error);\n            }\n        };\n        init();\n    }, []);\n    const login = async ()=>{\n        // IMP START - Login\n        const web3authProvider = await web3auth.connect();\n        // IMP END - Login\n        setProvider(web3authProvider);\n        if (web3auth.connected) {\n            setLoggedIn(true);\n        }\n    };\n    const getUserInfo = async ()=>{\n        // IMP START - Get User Information\n        const user = await web3auth.getUserInfo();\n        // IMP END - Get User Information\n        uiConsole(user);\n    };\n    const logout = async ()=>{\n        // IMP START - Logout\n        await web3auth.logout();\n        // IMP END - Logout\n        setProvider(null);\n        setLoggedIn(false);\n        uiConsole(\"logged out\");\n    };\n    // IMP START - Blockchain Calls\n    const getAccounts = async ()=>{\n        if (!provider) {\n            uiConsole(\"provider not initialized yet\");\n            return;\n        }\n        const web3 = new web3__WEBPACK_IMPORTED_MODULE_4__[\"default\"](provider);\n        // Get user's Ethereum public address\n        const address = await web3.eth.getAccounts();\n        uiConsole(address);\n    };\n    const getBalance = async ()=>{\n        if (!provider) {\n            uiConsole(\"provider not initialized yet\");\n            return;\n        }\n        const web3 = new web3__WEBPACK_IMPORTED_MODULE_4__[\"default\"](provider);\n        // Get user's Ethereum public address\n        const address = (await web3.eth.getAccounts())[0];\n        // Get user's balance in ether\n        const balance = web3.utils.fromWei(await web3.eth.getBalance(address), \"ether\");\n        uiConsole(balance);\n    };\n    const signMessage = async ()=>{\n        if (!provider) {\n            uiConsole(\"provider not initialized yet\");\n            return;\n        }\n        const web3 = new web3__WEBPACK_IMPORTED_MODULE_4__[\"default\"](provider);\n        // Get user's Ethereum public address\n        const fromAddress = (await web3.eth.getAccounts())[0];\n        const originalMessage = \"YOUR_MESSAGE\";\n        // Sign the message\n        const signedMessage = await web3.eth.personal.sign(originalMessage, fromAddress, \"test password!\" // configure your own password here.\n        );\n        uiConsole(signedMessage);\n    };\n    // IMP END - Blockchain Calls\n    function uiConsole() {\n        for(var _len = arguments.length, args = new Array(_len), _key = 0; _key < _len; _key++){\n            args[_key] = arguments[_key];\n        }\n        const el = document.querySelector(\"#console>p\");\n        if (el) {\n            el.innerHTML = JSON.stringify(args || {}, null, 2);\n            console.log(...args);\n        }\n    }\n    const loggedInView = /*#__PURE__*/ (0,react_jsx_dev_runtime__WEBPACK_IMPORTED_MODULE_0__.jsxDEV)(react_jsx_dev_runtime__WEBPACK_IMPORTED_MODULE_0__.Fragment, {\n        children: /*#__PURE__*/ (0,react_jsx_dev_runtime__WEBPACK_IMPORTED_MODULE_0__.jsxDEV)(\"div\", {\n            className: \"flex-container\",\n            children: [\n                /*#__PURE__*/ (0,react_jsx_dev_runtime__WEBPACK_IMPORTED_MODULE_0__.jsxDEV)(\"div\", {\n                    children: /*#__PURE__*/ (0,react_jsx_dev_runtime__WEBPACK_IMPORTED_MODULE_0__.jsxDEV)(\"button\", {\n                        onClick: getUserInfo,\n                        className: \"card\",\n                        children: \"Get User Info\"\n                    }, void 0, false, {\n                        fileName: \"/home/lucasia/ubuntu-proj/credbull/credbull-defi/packages/spike-auth/app/page.tsx\",\n                        lineNumber: 150,\n                        columnNumber: 11\n                    }, this)\n                }, void 0, false, {\n                    fileName: \"/home/lucasia/ubuntu-proj/credbull/credbull-defi/packages/spike-auth/app/page.tsx\",\n                    lineNumber: 149,\n                    columnNumber: 9\n                }, this),\n                /*#__PURE__*/ (0,react_jsx_dev_runtime__WEBPACK_IMPORTED_MODULE_0__.jsxDEV)(\"div\", {\n                    children: /*#__PURE__*/ (0,react_jsx_dev_runtime__WEBPACK_IMPORTED_MODULE_0__.jsxDEV)(\"button\", {\n                        onClick: getAccounts,\n                        className: \"card\",\n                        children: \"Get Accounts\"\n                    }, void 0, false, {\n                        fileName: \"/home/lucasia/ubuntu-proj/credbull/credbull-defi/packages/spike-auth/app/page.tsx\",\n                        lineNumber: 155,\n                        columnNumber: 11\n                    }, this)\n                }, void 0, false, {\n                    fileName: \"/home/lucasia/ubuntu-proj/credbull/credbull-defi/packages/spike-auth/app/page.tsx\",\n                    lineNumber: 154,\n                    columnNumber: 9\n                }, this),\n                /*#__PURE__*/ (0,react_jsx_dev_runtime__WEBPACK_IMPORTED_MODULE_0__.jsxDEV)(\"div\", {\n                    children: /*#__PURE__*/ (0,react_jsx_dev_runtime__WEBPACK_IMPORTED_MODULE_0__.jsxDEV)(\"button\", {\n                        onClick: getBalance,\n                        className: \"card\",\n                        children: \"Get Balance\"\n                    }, void 0, false, {\n                        fileName: \"/home/lucasia/ubuntu-proj/credbull/credbull-defi/packages/spike-auth/app/page.tsx\",\n                        lineNumber: 160,\n                        columnNumber: 11\n                    }, this)\n                }, void 0, false, {\n                    fileName: \"/home/lucasia/ubuntu-proj/credbull/credbull-defi/packages/spike-auth/app/page.tsx\",\n                    lineNumber: 159,\n                    columnNumber: 9\n                }, this),\n                /*#__PURE__*/ (0,react_jsx_dev_runtime__WEBPACK_IMPORTED_MODULE_0__.jsxDEV)(\"div\", {\n                    children: /*#__PURE__*/ (0,react_jsx_dev_runtime__WEBPACK_IMPORTED_MODULE_0__.jsxDEV)(\"button\", {\n                        onClick: signMessage,\n                        className: \"card\",\n                        children: \"Sign Message\"\n                    }, void 0, false, {\n                        fileName: \"/home/lucasia/ubuntu-proj/credbull/credbull-defi/packages/spike-auth/app/page.tsx\",\n                        lineNumber: 165,\n                        columnNumber: 11\n                    }, this)\n                }, void 0, false, {\n                    fileName: \"/home/lucasia/ubuntu-proj/credbull/credbull-defi/packages/spike-auth/app/page.tsx\",\n                    lineNumber: 164,\n                    columnNumber: 9\n                }, this),\n                /*#__PURE__*/ (0,react_jsx_dev_runtime__WEBPACK_IMPORTED_MODULE_0__.jsxDEV)(\"div\", {\n                    children: /*#__PURE__*/ (0,react_jsx_dev_runtime__WEBPACK_IMPORTED_MODULE_0__.jsxDEV)(\"button\", {\n                        onClick: logout,\n                        className: \"card\",\n                        children: \"Log Out\"\n                    }, void 0, false, {\n                        fileName: \"/home/lucasia/ubuntu-proj/credbull/credbull-defi/packages/spike-auth/app/page.tsx\",\n                        lineNumber: 170,\n                        columnNumber: 11\n                    }, this)\n                }, void 0, false, {\n                    fileName: \"/home/lucasia/ubuntu-proj/credbull/credbull-defi/packages/spike-auth/app/page.tsx\",\n                    lineNumber: 169,\n                    columnNumber: 9\n                }, this)\n            ]\n        }, void 0, true, {\n            fileName: \"/home/lucasia/ubuntu-proj/credbull/credbull-defi/packages/spike-auth/app/page.tsx\",\n            lineNumber: 148,\n            columnNumber: 7\n        }, this)\n    }, void 0, false);\n    const unloggedInView = /*#__PURE__*/ (0,react_jsx_dev_runtime__WEBPACK_IMPORTED_MODULE_0__.jsxDEV)(\"button\", {\n        onClick: login,\n        className: \"card\",\n        children: \"Login\"\n    }, void 0, false, {\n        fileName: \"/home/lucasia/ubuntu-proj/credbull/credbull-defi/packages/spike-auth/app/page.tsx\",\n        lineNumber: 179,\n        columnNumber: 5\n    }, this);\n    return /*#__PURE__*/ (0,react_jsx_dev_runtime__WEBPACK_IMPORTED_MODULE_0__.jsxDEV)(\"div\", {\n        className: \"container\",\n        children: [\n            /*#__PURE__*/ (0,react_jsx_dev_runtime__WEBPACK_IMPORTED_MODULE_0__.jsxDEV)(\"h1\", {\n                className: \"title\",\n                children: [\n                    /*#__PURE__*/ (0,react_jsx_dev_runtime__WEBPACK_IMPORTED_MODULE_0__.jsxDEV)(\"a\", {\n                        target: \"_blank\",\n                        href: \"https://web3auth.io/docs/sdk/pnp/web/modal\",\n                        rel: \"noreferrer\",\n                        children: [\n                            \"Web3Auth\",\n                            \" \"\n                        ]\n                    }, void 0, true, {\n                        fileName: \"/home/lucasia/ubuntu-proj/credbull/credbull-defi/packages/spike-auth/app/page.tsx\",\n                        lineNumber: 187,\n                        columnNumber: 9\n                    }, this),\n                    \"& NextJS Quick Start\"\n                ]\n            }, void 0, true, {\n                fileName: \"/home/lucasia/ubuntu-proj/credbull/credbull-defi/packages/spike-auth/app/page.tsx\",\n                lineNumber: 186,\n                columnNumber: 7\n            }, this),\n            /*#__PURE__*/ (0,react_jsx_dev_runtime__WEBPACK_IMPORTED_MODULE_0__.jsxDEV)(\"div\", {\n                className: \"grid\",\n                children: loggedIn ? loggedInView : unloggedInView\n            }, void 0, false, {\n                fileName: \"/home/lucasia/ubuntu-proj/credbull/credbull-defi/packages/spike-auth/app/page.tsx\",\n                lineNumber: 193,\n                columnNumber: 7\n            }, this),\n            /*#__PURE__*/ (0,react_jsx_dev_runtime__WEBPACK_IMPORTED_MODULE_0__.jsxDEV)(\"div\", {\n                id: \"console\",\n                style: {\n                    whiteSpace: \"pre-line\"\n                },\n                children: /*#__PURE__*/ (0,react_jsx_dev_runtime__WEBPACK_IMPORTED_MODULE_0__.jsxDEV)(\"p\", {\n                    style: {\n                        whiteSpace: \"pre-line\"\n                    }\n                }, void 0, false, {\n                    fileName: \"/home/lucasia/ubuntu-proj/credbull/credbull-defi/packages/spike-auth/app/page.tsx\",\n                    lineNumber: 195,\n                    columnNumber: 9\n                }, this)\n            }, void 0, false, {\n                fileName: \"/home/lucasia/ubuntu-proj/credbull/credbull-defi/packages/spike-auth/app/page.tsx\",\n                lineNumber: 194,\n                columnNumber: 7\n            }, this),\n            /*#__PURE__*/ (0,react_jsx_dev_runtime__WEBPACK_IMPORTED_MODULE_0__.jsxDEV)(\"footer\", {\n                className: \"footer\",\n                children: /*#__PURE__*/ (0,react_jsx_dev_runtime__WEBPACK_IMPORTED_MODULE_0__.jsxDEV)(\"a\", {\n                    href: \"https://github.com/Web3Auth/web3auth-pnp-examples/tree/main/web-modal-sdk/quick-starts/nextjs-modal-quick-start\",\n                    target: \"_blank\",\n                    rel: \"noopener noreferrer\",\n                    children: \"Source code\"\n                }, void 0, false, {\n                    fileName: \"/home/lucasia/ubuntu-proj/credbull/credbull-defi/packages/spike-auth/app/page.tsx\",\n                    lineNumber: 199,\n                    columnNumber: 9\n                }, this)\n            }, void 0, false, {\n                fileName: \"/home/lucasia/ubuntu-proj/credbull/credbull-defi/packages/spike-auth/app/page.tsx\",\n                lineNumber: 198,\n                columnNumber: 7\n            }, this)\n        ]\n    }, void 0, true, {\n        fileName: \"/home/lucasia/ubuntu-proj/credbull/credbull-defi/packages/spike-auth/app/page.tsx\",\n        lineNumber: 185,\n        columnNumber: 5\n    }, this);\n}\n_s(App, \"tB1iKQ47fGApTPlwXOXLIouAr50=\");\n_c = App;\n/* harmony default export */ __webpack_exports__[\"default\"] = (App);\nvar _c;\n$RefreshReg$(_c, \"App\");\n\n\n;\n    // Wrapped in an IIFE to avoid polluting the global scope\n    ;\n    (function () {\n        var _a, _b;\n        // Legacy CSS implementations will `eval` browser code in a Node.js context\n        // to extract CSS. For backwards compatibility, we need to check we're in a\n        // browser context before continuing.\n        if (typeof self !== 'undefined' &&\n            // AMP / No-JS mode does not inject these helpers:\n            '$RefreshHelpers$' in self) {\n            // @ts-ignore __webpack_module__ is global\n            var currentExports = module.exports;\n            // @ts-ignore __webpack_module__ is global\n            var prevExports = (_b = (_a = module.hot.data) === null || _a === void 0 ? void 0 : _a.prevExports) !== null && _b !== void 0 ? _b : null;\n            // This cannot happen in MainTemplate because the exports mismatch between\n            // templating and execution.\n            self.$RefreshHelpers$.registerExportsForReactRefresh(currentExports, module.id);\n            // A module can be accepted automatically based on its exports, e.g. when\n            // it is a Refresh Boundary.\n            if (self.$RefreshHelpers$.isReactRefreshBoundary(currentExports)) {\n                // Save the previous exports on update so we can compare the boundary\n                // signatures.\n                module.hot.dispose(function (data) {\n                    data.prevExports = currentExports;\n                });\n                // Unconditionally accept an update to this module, we'll check if it's\n                // still a Refresh Boundary later.\n                // @ts-ignore importMeta is replaced in the loader\n                module.hot.accept();\n                // This field is set when the previous version of this module was a\n                // Refresh Boundary, letting us know we need to check for invalidation or\n                // enqueue an update.\n                if (prevExports !== null) {\n                    // A boundary can become ineligible if its exports are incompatible\n                    // with the previous exports.\n                    //\n                    // For example, if you add/remove/change exports, we'll want to\n                    // re-execute the importing modules, and force those components to\n                    // re-render. Similarly, if you convert a class component to a\n                    // function, we want to invalidate the boundary.\n                    if (self.$RefreshHelpers$.shouldInvalidateReactRefreshBoundary(prevExports, currentExports)) {\n                        module.hot.invalidate();\n                    }\n                    else {\n                        self.$RefreshHelpers$.scheduleUpdate();\n                    }\n                }\n            }\n            else {\n                // Since we just executed the code for the module, it's possible that the\n                // new exports made it ineligible for being a boundary.\n                // We only care about the case when we were _previously_ a boundary,\n                // because we already accepted this update (accidental side effect).\n                var isNoLongerABoundary = prevExports !== null;\n                if (isNoLongerABoundary) {\n                    module.hot.invalidate();\n                }\n            }\n        }\n    })();\n//# sourceURL=[module]\n//# sourceMappingURL=data:application/json;charset=utf-8;base64,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QU87d0JBQVNDLE1BQUs7d0JBQTZDQyxLQUFJOzs0QkFBYTs0QkFDM0U7Ozs7Ozs7b0JBQ1A7Ozs7Ozs7MEJBSU4sOERBQUNUO2dCQUFJQyxXQUFVOzBCQUFRdEMsV0FBV29DLGVBQWVLOzs7Ozs7MEJBQ2pELDhEQUFDSjtnQkFBSVUsSUFBRztnQkFBVUMsT0FBTztvQkFBRUMsWUFBWTtnQkFBVzswQkFDaEQsNEVBQUNDO29CQUFFRixPQUFPO3dCQUFFQyxZQUFZO29CQUFXOzs7Ozs7Ozs7OzswQkFHckMsOERBQUNFO2dCQUFPYixXQUFVOzBCQUNoQiw0RUFBQ0s7b0JBQ0NFLE1BQUs7b0JBQ0xELFFBQU87b0JBQ1BFLEtBQUk7OEJBQ0w7Ozs7Ozs7Ozs7Ozs7Ozs7O0FBTVQ7R0E3S1NqRDtLQUFBQTtBQStLVCwrREFBZUEsR0FBR0EsRUFBQyIsInNvdXJjZXMiOlsid2VicGFjazovL19OX0UvLi9hcHAvcGFnZS50c3g/NzYwMyJdLCJzb3VyY2VzQ29udGVudCI6WyIvKiBlc2xpbnQtZGlzYWJsZSBAdHlwZXNjcmlwdC1lc2xpbnQvbm8tdXNlLWJlZm9yZS1kZWZpbmUgKi9cbi8qIGVzbGludC1kaXNhYmxlIG5vLWNvbnNvbGUgKi9cbi8qIGVzbGludC1kaXNhYmxlIEB0eXBlc2NyaXB0LWVzbGludC9uby1zaGFkb3cgKi9cblxuXCJ1c2UgY2xpZW50XCI7XG5cbi8vIElNUCBTVEFSVCAtIFF1aWNrIFN0YXJ0XG5pbXBvcnQgeyB1c2VFZmZlY3QsIHVzZVN0YXRlIH0gZnJvbSBcInJlYWN0XCI7XG4vLyBJTVAgRU5EIC0gUXVpY2sgU3RhcnRcbmltcG9ydCB7IFdlYjNBdXRoIH0gZnJvbSBcIkB3ZWIzYXV0aC9tb2RhbFwiO1xuaW1wb3J0IHsgQ0hBSU5fTkFNRVNQQUNFUywgSVByb3ZpZGVyIH0gZnJvbSBcIkB3ZWIzYXV0aC9iYXNlXCI7XG5pbXBvcnQgV2ViMyBmcm9tIFwid2ViM1wiO1xuXG4vLyBJTVAgU1RBUlQgLSBTREsgSW5pdGlhbGl6YXRpb25cbi8vIElNUCBTVEFSVCAtIERhc2hib2FyZCBSZWdpc3RyYXRpb25cbmNvbnN0IGNsaWVudElkID0gcHJvY2Vzcy5lbnYuV0VCM0FVVEhfQ0xJRU5UX0lEIC8vIGdldCBmcm9tIGh0dHBzOi8vZGFzaGJvYXJkLndlYjNhdXRoLmlvXG4vLyBJTVAgRU5EIC0gRGFzaGJvYXJkIFJlZ2lzdHJhdGlvblxuXG5jb25zdCBjaGFpbkNvbmZpZyA9IHtcbiAgY2hhaW5OYW1lc3BhY2U6IENIQUlOX05BTUVTUEFDRVMuRUlQMTU1LFxuICBjaGFpbklkOiBcIjB4MVwiLCAvLyBQbGVhc2UgdXNlIDB4MSBmb3IgTWFpbm5ldFxuICBycGNUYXJnZXQ6IFwiaHR0cHM6Ly9ycGMuYW5rci5jb20vZXRoXCIsXG4gIGRpc3BsYXlOYW1lOiBcIkV0aGVyZXVtIE1haW5uZXRcIixcbiAgYmxvY2tFeHBsb3JlcjogXCJodHRwczovL2V0aGVyc2Nhbi5pby9cIixcbiAgdGlja2VyOiBcIkVUSFwiLFxuICB0aWNrZXJOYW1lOiBcIkV0aGVyZXVtXCIsXG59O1xuXG5jb25zdCB3ZWIzYXV0aCA9IG5ldyBXZWIzQXV0aCh7XG4gIGNsaWVudElkLFxuICBjaGFpbkNvbmZpZyxcbiAgd2ViM0F1dGhOZXR3b3JrOiBcInNhcHBoaXJlX2Rldm5ldFwiLFxufSk7XG4vLyBJTVAgRU5EIC0gU0RLIEluaXRpYWxpemF0aW9uXG5cbmZ1bmN0aW9uIEFwcCgpIHtcbiAgY29uc3QgW3Byb3ZpZGVyLCBzZXRQcm92aWRlcl0gPSB1c2VTdGF0ZTxJUHJvdmlkZXIgfCBudWxsPihudWxsKTtcbiAgY29uc3QgW2xvZ2dlZEluLCBzZXRMb2dnZWRJbl0gPSB1c2VTdGF0ZShmYWxzZSk7XG5cbiAgdXNlRWZmZWN0KCgpID0+IHtcbiAgICBjb25zdCBpbml0ID0gYXN5bmMgKCkgPT4ge1xuICAgICAgdHJ5IHtcbiAgICAgICAgLy8gSU1QIFNUQVJUIC0gU0RLIEluaXRpYWxpemF0aW9uXG4gICAgICAgIGF3YWl0IHdlYjNhdXRoLmluaXRNb2RhbCgpO1xuICAgICAgICAvLyBJTVAgRU5EIC0gU0RLIEluaXRpYWxpemF0aW9uXG4gICAgICAgIHNldFByb3ZpZGVyKHdlYjNhdXRoLnByb3ZpZGVyKTtcblxuICAgICAgICBpZiAod2ViM2F1dGguY29ubmVjdGVkKSB7XG4gICAgICAgICAgc2V0TG9nZ2VkSW4odHJ1ZSk7XG4gICAgICAgIH1cbiAgICAgIH0gY2F0Y2ggKGVycm9yKSB7XG4gICAgICAgIGNvbnNvbGUuZXJyb3IoZXJyb3IpO1xuICAgICAgfVxuICAgIH07XG5cbiAgICBpbml0KCk7XG4gIH0sIFtdKTtcblxuICBjb25zdCBsb2dpbiA9IGFzeW5jICgpID0+IHtcbiAgICAvLyBJTVAgU1RBUlQgLSBMb2dpblxuICAgIGNvbnN0IHdlYjNhdXRoUHJvdmlkZXIgPSBhd2FpdCB3ZWIzYXV0aC5jb25uZWN0KCk7XG4gICAgLy8gSU1QIEVORCAtIExvZ2luXG4gICAgc2V0UHJvdmlkZXIod2ViM2F1dGhQcm92aWRlcik7XG4gICAgaWYgKHdlYjNhdXRoLmNvbm5lY3RlZCkge1xuICAgICAgc2V0TG9nZ2VkSW4odHJ1ZSk7XG4gICAgfVxuICB9O1xuXG4gIGNvbnN0IGdldFVzZXJJbmZvID0gYXN5bmMgKCkgPT4ge1xuICAgIC8vIElNUCBTVEFSVCAtIEdldCBVc2VyIEluZm9ybWF0aW9uXG4gICAgY29uc3QgdXNlciA9IGF3YWl0IHdlYjNhdXRoLmdldFVzZXJJbmZvKCk7XG4gICAgLy8gSU1QIEVORCAtIEdldCBVc2VyIEluZm9ybWF0aW9uXG4gICAgdWlDb25zb2xlKHVzZXIpO1xuICB9O1xuXG4gIGNvbnN0IGxvZ291dCA9IGFzeW5jICgpID0+IHtcbiAgICAvLyBJTVAgU1RBUlQgLSBMb2dvdXRcbiAgICBhd2FpdCB3ZWIzYXV0aC5sb2dvdXQoKTtcbiAgICAvLyBJTVAgRU5EIC0gTG9nb3V0XG4gICAgc2V0UHJvdmlkZXIobnVsbCk7XG4gICAgc2V0TG9nZ2VkSW4oZmFsc2UpO1xuICAgIHVpQ29uc29sZShcImxvZ2dlZCBvdXRcIik7XG4gIH07XG5cbiAgLy8gSU1QIFNUQVJUIC0gQmxvY2tjaGFpbiBDYWxsc1xuICBjb25zdCBnZXRBY2NvdW50cyA9IGFzeW5jICgpID0+IHtcbiAgICBpZiAoIXByb3ZpZGVyKSB7XG4gICAgICB1aUNvbnNvbGUoXCJwcm92aWRlciBub3QgaW5pdGlhbGl6ZWQgeWV0XCIpO1xuICAgICAgcmV0dXJuO1xuICAgIH1cbiAgICBjb25zdCB3ZWIzID0gbmV3IFdlYjMocHJvdmlkZXIgYXMgYW55KTtcblxuICAgIC8vIEdldCB1c2VyJ3MgRXRoZXJldW0gcHVibGljIGFkZHJlc3NcbiAgICBjb25zdCBhZGRyZXNzID0gYXdhaXQgd2ViMy5ldGguZ2V0QWNjb3VudHMoKTtcbiAgICB1aUNvbnNvbGUoYWRkcmVzcyk7XG4gIH07XG5cbiAgY29uc3QgZ2V0QmFsYW5jZSA9IGFzeW5jICgpID0+IHtcbiAgICBpZiAoIXByb3ZpZGVyKSB7XG4gICAgICB1aUNvbnNvbGUoXCJwcm92aWRlciBub3QgaW5pdGlhbGl6ZWQgeWV0XCIpO1xuICAgICAgcmV0dXJuO1xuICAgIH1cbiAgICBjb25zdCB3ZWIzID0gbmV3IFdlYjMocHJvdmlkZXIgYXMgYW55KTtcblxuICAgIC8vIEdldCB1c2VyJ3MgRXRoZXJldW0gcHVibGljIGFkZHJlc3NcbiAgICBjb25zdCBhZGRyZXNzID0gKGF3YWl0IHdlYjMuZXRoLmdldEFjY291bnRzKCkpWzBdO1xuXG4gICAgLy8gR2V0IHVzZXIncyBiYWxhbmNlIGluIGV0aGVyXG4gICAgY29uc3QgYmFsYW5jZSA9IHdlYjMudXRpbHMuZnJvbVdlaShcbiAgICAgIGF3YWl0IHdlYjMuZXRoLmdldEJhbGFuY2UoYWRkcmVzcyksIC8vIEJhbGFuY2UgaXMgaW4gd2VpXG4gICAgICBcImV0aGVyXCJcbiAgICApO1xuICAgIHVpQ29uc29sZShiYWxhbmNlKTtcbiAgfTtcblxuICBjb25zdCBzaWduTWVzc2FnZSA9IGFzeW5jICgpID0+IHtcbiAgICBpZiAoIXByb3ZpZGVyKSB7XG4gICAgICB1aUNvbnNvbGUoXCJwcm92aWRlciBub3QgaW5pdGlhbGl6ZWQgeWV0XCIpO1xuICAgICAgcmV0dXJuO1xuICAgIH1cbiAgICBjb25zdCB3ZWIzID0gbmV3IFdlYjMocHJvdmlkZXIgYXMgYW55KTtcblxuICAgIC8vIEdldCB1c2VyJ3MgRXRoZXJldW0gcHVibGljIGFkZHJlc3NcbiAgICBjb25zdCBmcm9tQWRkcmVzcyA9IChhd2FpdCB3ZWIzLmV0aC5nZXRBY2NvdW50cygpKVswXTtcblxuICAgIGNvbnN0IG9yaWdpbmFsTWVzc2FnZSA9IFwiWU9VUl9NRVNTQUdFXCI7XG5cbiAgICAvLyBTaWduIHRoZSBtZXNzYWdlXG4gICAgY29uc3Qgc2lnbmVkTWVzc2FnZSA9IGF3YWl0IHdlYjMuZXRoLnBlcnNvbmFsLnNpZ24oXG4gICAgICBvcmlnaW5hbE1lc3NhZ2UsXG4gICAgICBmcm9tQWRkcmVzcyxcbiAgICAgIFwidGVzdCBwYXNzd29yZCFcIiAvLyBjb25maWd1cmUgeW91ciBvd24gcGFzc3dvcmQgaGVyZS5cbiAgICApO1xuICAgIHVpQ29uc29sZShzaWduZWRNZXNzYWdlKTtcbiAgfTtcbiAgLy8gSU1QIEVORCAtIEJsb2NrY2hhaW4gQ2FsbHNcblxuICBmdW5jdGlvbiB1aUNvbnNvbGUoLi4uYXJnczogYW55W10pOiB2b2lkIHtcbiAgICBjb25zdCBlbCA9IGRvY3VtZW50LnF1ZXJ5U2VsZWN0b3IoXCIjY29uc29sZT5wXCIpO1xuICAgIGlmIChlbCkge1xuICAgICAgZWwuaW5uZXJIVE1MID0gSlNPTi5zdHJpbmdpZnkoYXJncyB8fCB7fSwgbnVsbCwgMik7XG4gICAgICBjb25zb2xlLmxvZyguLi5hcmdzKTtcbiAgICB9XG4gIH1cblxuICBjb25zdCBsb2dnZWRJblZpZXcgPSAoXG4gICAgPD5cbiAgICAgIDxkaXYgY2xhc3NOYW1lPVwiZmxleC1jb250YWluZXJcIj5cbiAgICAgICAgPGRpdj5cbiAgICAgICAgICA8YnV0dG9uIG9uQ2xpY2s9e2dldFVzZXJJbmZvfSBjbGFzc05hbWU9XCJjYXJkXCI+XG4gICAgICAgICAgICBHZXQgVXNlciBJbmZvXG4gICAgICAgICAgPC9idXR0b24+XG4gICAgICAgIDwvZGl2PlxuICAgICAgICA8ZGl2PlxuICAgICAgICAgIDxidXR0b24gb25DbGljaz17Z2V0QWNjb3VudHN9IGNsYXNzTmFtZT1cImNhcmRcIj5cbiAgICAgICAgICAgIEdldCBBY2NvdW50c1xuICAgICAgICAgIDwvYnV0dG9uPlxuICAgICAgICA8L2Rpdj5cbiAgICAgICAgPGRpdj5cbiAgICAgICAgICA8YnV0dG9uIG9uQ2xpY2s9e2dldEJhbGFuY2V9IGNsYXNzTmFtZT1cImNhcmRcIj5cbiAgICAgICAgICAgIEdldCBCYWxhbmNlXG4gICAgICAgICAgPC9idXR0b24+XG4gICAgICAgIDwvZGl2PlxuICAgICAgICA8ZGl2PlxuICAgICAgICAgIDxidXR0b24gb25DbGljaz17c2lnbk1lc3NhZ2V9IGNsYXNzTmFtZT1cImNhcmRcIj5cbiAgICAgICAgICAgIFNpZ24gTWVzc2FnZVxuICAgICAgICAgIDwvYnV0dG9uPlxuICAgICAgICA8L2Rpdj5cbiAgICAgICAgPGRpdj5cbiAgICAgICAgICA8YnV0dG9uIG9uQ2xpY2s9e2xvZ291dH0gY2xhc3NOYW1lPVwiY2FyZFwiPlxuICAgICAgICAgICAgTG9nIE91dFxuICAgICAgICAgIDwvYnV0dG9uPlxuICAgICAgICA8L2Rpdj5cbiAgICAgIDwvZGl2PlxuICAgIDwvPlxuICApO1xuXG4gIGNvbnN0IHVubG9nZ2VkSW5WaWV3ID0gKFxuICAgIDxidXR0b24gb25DbGljaz17bG9naW59IGNsYXNzTmFtZT1cImNhcmRcIj5cbiAgICAgIExvZ2luXG4gICAgPC9idXR0b24+XG4gICk7XG5cbiAgcmV0dXJuIChcbiAgICA8ZGl2IGNsYXNzTmFtZT1cImNvbnRhaW5lclwiPlxuICAgICAgPGgxIGNsYXNzTmFtZT1cInRpdGxlXCI+XG4gICAgICAgIDxhIHRhcmdldD1cIl9ibGFua1wiIGhyZWY9XCJodHRwczovL3dlYjNhdXRoLmlvL2RvY3Mvc2RrL3BucC93ZWIvbW9kYWxcIiByZWw9XCJub3JlZmVycmVyXCI+XG4gICAgICAgICAgV2ViM0F1dGh7XCIgXCJ9XG4gICAgICAgIDwvYT5cbiAgICAgICAgJiBOZXh0SlMgUXVpY2sgU3RhcnRcbiAgICAgIDwvaDE+XG5cbiAgICAgIDxkaXYgY2xhc3NOYW1lPVwiZ3JpZFwiPntsb2dnZWRJbiA/IGxvZ2dlZEluVmlldyA6IHVubG9nZ2VkSW5WaWV3fTwvZGl2PlxuICAgICAgPGRpdiBpZD1cImNvbnNvbGVcIiBzdHlsZT17eyB3aGl0ZVNwYWNlOiBcInByZS1saW5lXCIgfX0+XG4gICAgICAgIDxwIHN0eWxlPXt7IHdoaXRlU3BhY2U6IFwicHJlLWxpbmVcIiB9fT48L3A+XG4gICAgICA8L2Rpdj5cblxuICAgICAgPGZvb3RlciBjbGFzc05hbWU9XCJmb290ZXJcIj5cbiAgICAgICAgPGFcbiAgICAgICAgICBocmVmPVwiaHR0cHM6Ly9naXRodWIuY29tL1dlYjNBdXRoL3dlYjNhdXRoLXBucC1leGFtcGxlcy90cmVlL21haW4vd2ViLW1vZGFsLXNkay9xdWljay1zdGFydHMvbmV4dGpzLW1vZGFsLXF1aWNrLXN0YXJ0XCJcbiAgICAgICAgICB0YXJnZXQ9XCJfYmxhbmtcIlxuICAgICAgICAgIHJlbD1cIm5vb3BlbmVyIG5vcmVmZXJyZXJcIlxuICAgICAgICA+XG4gICAgICAgICAgU291cmNlIGNvZGVcbiAgICAgICAgPC9hPlxuICAgICAgPC9mb290ZXI+XG4gICAgPC9kaXY+XG4gICk7XG59XG5cbmV4cG9ydCBkZWZhdWx0IEFwcDtcbiJdLCJuYW1lcyI6WyJ1c2VFZmZlY3QiLCJ1c2VTdGF0ZSIsIldlYjNBdXRoIiwiQ0hBSU5fTkFNRVNQQUNFUyIsIldlYjMiLCJjbGllbnRJZCIsInByb2Nlc3MiLCJlbnYiLCJXRUIzQVVUSF9DTElFTlRfSUQiLCJjaGFpbkNvbmZpZyIsImNoYWluTmFtZXNwYWNlIiwiRUlQMTU1IiwiY2hhaW5JZCIsInJwY1RhcmdldCIsImRpc3BsYXlOYW1lIiwiYmxvY2tFeHBsb3JlciIsInRpY2tlciIsInRpY2tlck5hbWUiLCJ3ZWIzYXV0aCIsIndlYjNBdXRoTmV0d29yayIsIkFwcCIsInByb3ZpZGVyIiwic2V0UHJvdmlkZXIiLCJsb2dnZWRJbiIsInNldExvZ2dlZEluIiwiaW5pdCIsImluaXRNb2RhbCIsImNvbm5lY3RlZCIsImVycm9yIiwiY29uc29sZSIsImxvZ2luIiwid2ViM2F1dGhQcm92aWRlciIsImNvbm5lY3QiLCJnZXRVc2VySW5mbyIsInVzZXIiLCJ1aUNvbnNvbGUiLCJsb2dvdXQiLCJnZXRBY2NvdW50cyIsIndlYjMiLCJhZGRyZXNzIiwiZXRoIiwiZ2V0QmFsYW5jZSIsImJhbGFuY2UiLCJ1dGlscyIsImZyb21XZWkiLCJzaWduTWVzc2FnZSIsImZyb21BZGRyZXNzIiwib3JpZ2luYWxNZXNzYWdlIiwic2lnbmVkTWVzc2FnZSIsInBlcnNvbmFsIiwic2lnbiIsImFyZ3MiLCJlbCIsImRvY3VtZW50IiwicXVlcnlTZWxlY3RvciIsImlubmVySFRNTCIsIkpTT04iLCJzdHJpbmdpZnkiLCJsb2ciLCJsb2dnZWRJblZpZXciLCJkaXYiLCJjbGFzc05hbWUiLCJidXR0b24iLCJvbkNsaWNrIiwidW5sb2dnZWRJblZpZXciLCJoMSIsImEiLCJ0YXJnZXQiLCJocmVmIiwicmVsIiwiaWQiLCJzdHlsZSIsIndoaXRlU3BhY2UiLCJwIiwiZm9vdGVyIl0sInNvdXJjZVJvb3QiOiIifQ==\n//# sourceURL=webpack-internal:///(app-client)/./app/page.tsx\n"));

/***/ })

});