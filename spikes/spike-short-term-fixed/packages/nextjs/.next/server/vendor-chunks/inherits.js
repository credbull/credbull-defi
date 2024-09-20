/*
 * ATTENTION: An "eval-source-map" devtool has been used.
 * This devtool is neither made for production nor for readable output files.
 * It uses "eval()" calls to create a separate source file with attached SourceMaps in the browser devtools.
 * If you are trying to read the output file, select a different devtool (https://webpack.js.org/configuration/devtool/)
 * or disable the default devtool with "devtool: false".
 * If you are looking for production-ready output files, see mode: "production" (https://webpack.js.org/configuration/mode/).
 */
exports.id = "vendor-chunks/inherits";
exports.ids = ["vendor-chunks/inherits"];
exports.modules = {

/***/ "(ssr)/./node_modules/inherits/inherits.js":
/*!*******************************************!*\
  !*** ./node_modules/inherits/inherits.js ***!
  \*******************************************/
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

eval("try {\n    var util = __webpack_require__(/*! util */ \"util\");\n    /* istanbul ignore next */ if (typeof util.inherits !== \"function\") throw \"\";\n    module.exports = util.inherits;\n} catch (e) {\n    /* istanbul ignore next */ module.exports = __webpack_require__(/*! ./inherits_browser.js */ \"(ssr)/./node_modules/inherits/inherits_browser.js\");\n}\n//# sourceURL=[module]\n//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiKHNzcikvLi9ub2RlX21vZHVsZXMvaW5oZXJpdHMvaW5oZXJpdHMuanMiLCJtYXBwaW5ncyI6IkFBQUEsSUFBSTtJQUNGLElBQUlBLE9BQU9DLG1CQUFPQSxDQUFDO0lBQ25CLHdCQUF3QixHQUN4QixJQUFJLE9BQU9ELEtBQUtFLFFBQVEsS0FBSyxZQUFZLE1BQU07SUFDL0NDLE9BQU9DLE9BQU8sR0FBR0osS0FBS0UsUUFBUTtBQUNoQyxFQUFFLE9BQU9HLEdBQUc7SUFDVix3QkFBd0IsR0FDeEJGLHNIQUF5QjtBQUMzQiIsInNvdXJjZXMiOlsid2VicGFjazovL0BzZS0yL25leHRqcy8uL25vZGVfbW9kdWxlcy9pbmhlcml0cy9pbmhlcml0cy5qcz83MjYyIl0sInNvdXJjZXNDb250ZW50IjpbInRyeSB7XG4gIHZhciB1dGlsID0gcmVxdWlyZSgndXRpbCcpO1xuICAvKiBpc3RhbmJ1bCBpZ25vcmUgbmV4dCAqL1xuICBpZiAodHlwZW9mIHV0aWwuaW5oZXJpdHMgIT09ICdmdW5jdGlvbicpIHRocm93ICcnO1xuICBtb2R1bGUuZXhwb3J0cyA9IHV0aWwuaW5oZXJpdHM7XG59IGNhdGNoIChlKSB7XG4gIC8qIGlzdGFuYnVsIGlnbm9yZSBuZXh0ICovXG4gIG1vZHVsZS5leHBvcnRzID0gcmVxdWlyZSgnLi9pbmhlcml0c19icm93c2VyLmpzJyk7XG59XG4iXSwibmFtZXMiOlsidXRpbCIsInJlcXVpcmUiLCJpbmhlcml0cyIsIm1vZHVsZSIsImV4cG9ydHMiLCJlIl0sInNvdXJjZVJvb3QiOiIifQ==\n//# sourceURL=webpack-internal:///(ssr)/./node_modules/inherits/inherits.js\n");

/***/ }),

/***/ "(ssr)/./node_modules/inherits/inherits_browser.js":
/*!***************************************************!*\
  !*** ./node_modules/inherits/inherits_browser.js ***!
  \***************************************************/
/***/ ((module) => {

eval("if (typeof Object.create === \"function\") {\n    // implementation from standard node.js 'util' module\n    module.exports = function inherits(ctor, superCtor) {\n        if (superCtor) {\n            ctor.super_ = superCtor;\n            ctor.prototype = Object.create(superCtor.prototype, {\n                constructor: {\n                    value: ctor,\n                    enumerable: false,\n                    writable: true,\n                    configurable: true\n                }\n            });\n        }\n    };\n} else {\n    // old school shim for old browsers\n    module.exports = function inherits(ctor, superCtor) {\n        if (superCtor) {\n            ctor.super_ = superCtor;\n            var TempCtor = function() {};\n            TempCtor.prototype = superCtor.prototype;\n            ctor.prototype = new TempCtor();\n            ctor.prototype.constructor = ctor;\n        }\n    };\n}\n//# sourceURL=[module]\n//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIndlYnBhY2s6Ly9Ac2UtMi9uZXh0anMvLi9ub2RlX21vZHVsZXMvaW5oZXJpdHMvaW5oZXJpdHNfYnJvd3Nlci5qcz9lM2M2Il0sInNvdXJjZXNDb250ZW50IjpbImlmICh0eXBlb2YgT2JqZWN0LmNyZWF0ZSA9PT0gJ2Z1bmN0aW9uJykge1xuICAvLyBpbXBsZW1lbnRhdGlvbiBmcm9tIHN0YW5kYXJkIG5vZGUuanMgJ3V0aWwnIG1vZHVsZVxuICBtb2R1bGUuZXhwb3J0cyA9IGZ1bmN0aW9uIGluaGVyaXRzKGN0b3IsIHN1cGVyQ3Rvcikge1xuICAgIGlmIChzdXBlckN0b3IpIHtcbiAgICAgIGN0b3Iuc3VwZXJfID0gc3VwZXJDdG9yXG4gICAgICBjdG9yLnByb3RvdHlwZSA9IE9iamVjdC5jcmVhdGUoc3VwZXJDdG9yLnByb3RvdHlwZSwge1xuICAgICAgICBjb25zdHJ1Y3Rvcjoge1xuICAgICAgICAgIHZhbHVlOiBjdG9yLFxuICAgICAgICAgIGVudW1lcmFibGU6IGZhbHNlLFxuICAgICAgICAgIHdyaXRhYmxlOiB0cnVlLFxuICAgICAgICAgIGNvbmZpZ3VyYWJsZTogdHJ1ZVxuICAgICAgICB9XG4gICAgICB9KVxuICAgIH1cbiAgfTtcbn0gZWxzZSB7XG4gIC8vIG9sZCBzY2hvb2wgc2hpbSBmb3Igb2xkIGJyb3dzZXJzXG4gIG1vZHVsZS5leHBvcnRzID0gZnVuY3Rpb24gaW5oZXJpdHMoY3Rvciwgc3VwZXJDdG9yKSB7XG4gICAgaWYgKHN1cGVyQ3Rvcikge1xuICAgICAgY3Rvci5zdXBlcl8gPSBzdXBlckN0b3JcbiAgICAgIHZhciBUZW1wQ3RvciA9IGZ1bmN0aW9uICgpIHt9XG4gICAgICBUZW1wQ3Rvci5wcm90b3R5cGUgPSBzdXBlckN0b3IucHJvdG90eXBlXG4gICAgICBjdG9yLnByb3RvdHlwZSA9IG5ldyBUZW1wQ3RvcigpXG4gICAgICBjdG9yLnByb3RvdHlwZS5jb25zdHJ1Y3RvciA9IGN0b3JcbiAgICB9XG4gIH1cbn1cbiJdLCJuYW1lcyI6WyJPYmplY3QiLCJjcmVhdGUiLCJtb2R1bGUiLCJleHBvcnRzIiwiaW5oZXJpdHMiLCJjdG9yIiwic3VwZXJDdG9yIiwic3VwZXJfIiwicHJvdG90eXBlIiwiY29uc3RydWN0b3IiLCJ2YWx1ZSIsImVudW1lcmFibGUiLCJ3cml0YWJsZSIsImNvbmZpZ3VyYWJsZSIsIlRlbXBDdG9yIl0sIm1hcHBpbmdzIjoiQUFBQSxJQUFJLE9BQU9BLE9BQU9DLE1BQU0sS0FBSyxZQUFZO0lBQ3ZDLHFEQUFxRDtJQUNyREMsT0FBT0MsT0FBTyxHQUFHLFNBQVNDLFNBQVNDLElBQUksRUFBRUMsU0FBUztRQUNoRCxJQUFJQSxXQUFXO1lBQ2JELEtBQUtFLE1BQU0sR0FBR0Q7WUFDZEQsS0FBS0csU0FBUyxHQUFHUixPQUFPQyxNQUFNLENBQUNLLFVBQVVFLFNBQVMsRUFBRTtnQkFDbERDLGFBQWE7b0JBQ1hDLE9BQU9MO29CQUNQTSxZQUFZO29CQUNaQyxVQUFVO29CQUNWQyxjQUFjO2dCQUNoQjtZQUNGO1FBQ0Y7SUFDRjtBQUNGLE9BQU87SUFDTCxtQ0FBbUM7SUFDbkNYLE9BQU9DLE9BQU8sR0FBRyxTQUFTQyxTQUFTQyxJQUFJLEVBQUVDLFNBQVM7UUFDaEQsSUFBSUEsV0FBVztZQUNiRCxLQUFLRSxNQUFNLEdBQUdEO1lBQ2QsSUFBSVEsV0FBVyxZQUFhO1lBQzVCQSxTQUFTTixTQUFTLEdBQUdGLFVBQVVFLFNBQVM7WUFDeENILEtBQUtHLFNBQVMsR0FBRyxJQUFJTTtZQUNyQlQsS0FBS0csU0FBUyxDQUFDQyxXQUFXLEdBQUdKO1FBQy9CO0lBQ0Y7QUFDRiIsImZpbGUiOiIoc3NyKS8uL25vZGVfbW9kdWxlcy9pbmhlcml0cy9pbmhlcml0c19icm93c2VyLmpzIiwic291cmNlUm9vdCI6IiJ9\n//# sourceURL=webpack-internal:///(ssr)/./node_modules/inherits/inherits_browser.js\n");

/***/ })

};
;