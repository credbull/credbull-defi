"use strict";
/*
 * ATTENTION: An "eval-source-map" devtool has been used.
 * This devtool is neither made for production nor for readable output files.
 * It uses "eval()" calls to create a separate source file with attached SourceMaps in the browser devtools.
 * If you are trying to read the output file, select a different devtool (https://webpack.js.org/configuration/devtool/)
 * or disable the default devtool with "devtool: false".
 * If you are looking for production-ready output files, see mode: "production" (https://webpack.js.org/configuration/mode/).
 */
exports.id = "vendor-chunks/process-warning";
exports.ids = ["vendor-chunks/process-warning"];
exports.modules = {

/***/ "(ssr)/./node_modules/process-warning/index.js":
/*!***********************************************!*\
  !*** ./node_modules/process-warning/index.js ***!
  \***********************************************/
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

eval("\nconst { format } = __webpack_require__(/*! util */ \"util\");\nfunction build() {\n    const codes = {};\n    const emitted = new Map();\n    function create(name, code, message) {\n        if (!name) throw new Error(\"Warning name must not be empty\");\n        if (!code) throw new Error(\"Warning code must not be empty\");\n        if (!message) throw new Error(\"Warning message must not be empty\");\n        code = code.toUpperCase();\n        if (codes[code] !== undefined) {\n            throw new Error(`The code '${code}' already exist`);\n        }\n        function buildWarnOpts(a, b, c) {\n            // more performant than spread (...) operator\n            let formatted;\n            if (a && b && c) {\n                formatted = format(message, a, b, c);\n            } else if (a && b) {\n                formatted = format(message, a, b);\n            } else if (a) {\n                formatted = format(message, a);\n            } else {\n                formatted = message;\n            }\n            return {\n                code,\n                name,\n                message: formatted\n            };\n        }\n        emitted.set(code, false);\n        codes[code] = buildWarnOpts;\n        return codes[code];\n    }\n    function emit(code, a, b, c) {\n        if (codes[code] === undefined) throw new Error(`The code '${code}' does not exist`);\n        if (emitted.get(code) === true) return;\n        emitted.set(code, true);\n        const warning = codes[code](a, b, c);\n        process.emitWarning(warning.message, warning.name, warning.code);\n    }\n    return {\n        create,\n        emit,\n        emitted\n    };\n}\nmodule.exports = build;\n//# sourceURL=[module]\n//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiKHNzcikvLi9ub2RlX21vZHVsZXMvcHJvY2Vzcy13YXJuaW5nL2luZGV4LmpzIiwibWFwcGluZ3MiOiJBQUFBO0FBRUEsTUFBTSxFQUFFQSxNQUFNLEVBQUUsR0FBR0MsbUJBQU9BLENBQUM7QUFFM0IsU0FBU0M7SUFDUCxNQUFNQyxRQUFRLENBQUM7SUFDZixNQUFNQyxVQUFVLElBQUlDO0lBRXBCLFNBQVNDLE9BQVFDLElBQUksRUFBRUMsSUFBSSxFQUFFQyxPQUFPO1FBQ2xDLElBQUksQ0FBQ0YsTUFBTSxNQUFNLElBQUlHLE1BQU07UUFDM0IsSUFBSSxDQUFDRixNQUFNLE1BQU0sSUFBSUUsTUFBTTtRQUMzQixJQUFJLENBQUNELFNBQVMsTUFBTSxJQUFJQyxNQUFNO1FBRTlCRixPQUFPQSxLQUFLRyxXQUFXO1FBRXZCLElBQUlSLEtBQUssQ0FBQ0ssS0FBSyxLQUFLSSxXQUFXO1lBQzdCLE1BQU0sSUFBSUYsTUFBTSxDQUFDLFVBQVUsRUFBRUYsS0FBSyxlQUFlLENBQUM7UUFDcEQ7UUFFQSxTQUFTSyxjQUFlQyxDQUFDLEVBQUVDLENBQUMsRUFBRUMsQ0FBQztZQUM3Qiw2Q0FBNkM7WUFDN0MsSUFBSUM7WUFDSixJQUFJSCxLQUFLQyxLQUFLQyxHQUFHO2dCQUNmQyxZQUFZakIsT0FBT1MsU0FBU0ssR0FBR0MsR0FBR0M7WUFDcEMsT0FBTyxJQUFJRixLQUFLQyxHQUFHO2dCQUNqQkUsWUFBWWpCLE9BQU9TLFNBQVNLLEdBQUdDO1lBQ2pDLE9BQU8sSUFBSUQsR0FBRztnQkFDWkcsWUFBWWpCLE9BQU9TLFNBQVNLO1lBQzlCLE9BQU87Z0JBQ0xHLFlBQVlSO1lBQ2Q7WUFFQSxPQUFPO2dCQUNMRDtnQkFDQUQ7Z0JBQ0FFLFNBQVNRO1lBQ1g7UUFDRjtRQUVBYixRQUFRYyxHQUFHLENBQUNWLE1BQU07UUFDbEJMLEtBQUssQ0FBQ0ssS0FBSyxHQUFHSztRQUVkLE9BQU9WLEtBQUssQ0FBQ0ssS0FBSztJQUNwQjtJQUVBLFNBQVNXLEtBQU1YLElBQUksRUFBRU0sQ0FBQyxFQUFFQyxDQUFDLEVBQUVDLENBQUM7UUFDMUIsSUFBSWIsS0FBSyxDQUFDSyxLQUFLLEtBQUtJLFdBQVcsTUFBTSxJQUFJRixNQUFNLENBQUMsVUFBVSxFQUFFRixLQUFLLGdCQUFnQixDQUFDO1FBQ2xGLElBQUlKLFFBQVFnQixHQUFHLENBQUNaLFVBQVUsTUFBTTtRQUNoQ0osUUFBUWMsR0FBRyxDQUFDVixNQUFNO1FBRWxCLE1BQU1hLFVBQVVsQixLQUFLLENBQUNLLEtBQUssQ0FBQ00sR0FBR0MsR0FBR0M7UUFDbENNLFFBQVFDLFdBQVcsQ0FBQ0YsUUFBUVosT0FBTyxFQUFFWSxRQUFRZCxJQUFJLEVBQUVjLFFBQVFiLElBQUk7SUFDakU7SUFFQSxPQUFPO1FBQ0xGO1FBQ0FhO1FBQ0FmO0lBQ0Y7QUFDRjtBQUVBb0IsT0FBT0MsT0FBTyxHQUFHdkIiLCJzb3VyY2VzIjpbIndlYnBhY2s6Ly9Ac2UtMi9uZXh0anMvLi9ub2RlX21vZHVsZXMvcHJvY2Vzcy13YXJuaW5nL2luZGV4LmpzPzkxZmYiXSwic291cmNlc0NvbnRlbnQiOlsiJ3VzZSBzdHJpY3QnXG5cbmNvbnN0IHsgZm9ybWF0IH0gPSByZXF1aXJlKCd1dGlsJylcblxuZnVuY3Rpb24gYnVpbGQgKCkge1xuICBjb25zdCBjb2RlcyA9IHt9XG4gIGNvbnN0IGVtaXR0ZWQgPSBuZXcgTWFwKClcblxuICBmdW5jdGlvbiBjcmVhdGUgKG5hbWUsIGNvZGUsIG1lc3NhZ2UpIHtcbiAgICBpZiAoIW5hbWUpIHRocm93IG5ldyBFcnJvcignV2FybmluZyBuYW1lIG11c3Qgbm90IGJlIGVtcHR5JylcbiAgICBpZiAoIWNvZGUpIHRocm93IG5ldyBFcnJvcignV2FybmluZyBjb2RlIG11c3Qgbm90IGJlIGVtcHR5JylcbiAgICBpZiAoIW1lc3NhZ2UpIHRocm93IG5ldyBFcnJvcignV2FybmluZyBtZXNzYWdlIG11c3Qgbm90IGJlIGVtcHR5JylcblxuICAgIGNvZGUgPSBjb2RlLnRvVXBwZXJDYXNlKClcblxuICAgIGlmIChjb2Rlc1tjb2RlXSAhPT0gdW5kZWZpbmVkKSB7XG4gICAgICB0aHJvdyBuZXcgRXJyb3IoYFRoZSBjb2RlICcke2NvZGV9JyBhbHJlYWR5IGV4aXN0YClcbiAgICB9XG5cbiAgICBmdW5jdGlvbiBidWlsZFdhcm5PcHRzIChhLCBiLCBjKSB7XG4gICAgICAvLyBtb3JlIHBlcmZvcm1hbnQgdGhhbiBzcHJlYWQgKC4uLikgb3BlcmF0b3JcbiAgICAgIGxldCBmb3JtYXR0ZWRcbiAgICAgIGlmIChhICYmIGIgJiYgYykge1xuICAgICAgICBmb3JtYXR0ZWQgPSBmb3JtYXQobWVzc2FnZSwgYSwgYiwgYylcbiAgICAgIH0gZWxzZSBpZiAoYSAmJiBiKSB7XG4gICAgICAgIGZvcm1hdHRlZCA9IGZvcm1hdChtZXNzYWdlLCBhLCBiKVxuICAgICAgfSBlbHNlIGlmIChhKSB7XG4gICAgICAgIGZvcm1hdHRlZCA9IGZvcm1hdChtZXNzYWdlLCBhKVxuICAgICAgfSBlbHNlIHtcbiAgICAgICAgZm9ybWF0dGVkID0gbWVzc2FnZVxuICAgICAgfVxuXG4gICAgICByZXR1cm4ge1xuICAgICAgICBjb2RlLFxuICAgICAgICBuYW1lLFxuICAgICAgICBtZXNzYWdlOiBmb3JtYXR0ZWRcbiAgICAgIH1cbiAgICB9XG5cbiAgICBlbWl0dGVkLnNldChjb2RlLCBmYWxzZSlcbiAgICBjb2Rlc1tjb2RlXSA9IGJ1aWxkV2Fybk9wdHNcblxuICAgIHJldHVybiBjb2Rlc1tjb2RlXVxuICB9XG5cbiAgZnVuY3Rpb24gZW1pdCAoY29kZSwgYSwgYiwgYykge1xuICAgIGlmIChjb2Rlc1tjb2RlXSA9PT0gdW5kZWZpbmVkKSB0aHJvdyBuZXcgRXJyb3IoYFRoZSBjb2RlICcke2NvZGV9JyBkb2VzIG5vdCBleGlzdGApXG4gICAgaWYgKGVtaXR0ZWQuZ2V0KGNvZGUpID09PSB0cnVlKSByZXR1cm5cbiAgICBlbWl0dGVkLnNldChjb2RlLCB0cnVlKVxuXG4gICAgY29uc3Qgd2FybmluZyA9IGNvZGVzW2NvZGVdKGEsIGIsIGMpXG4gICAgcHJvY2Vzcy5lbWl0V2FybmluZyh3YXJuaW5nLm1lc3NhZ2UsIHdhcm5pbmcubmFtZSwgd2FybmluZy5jb2RlKVxuICB9XG5cbiAgcmV0dXJuIHtcbiAgICBjcmVhdGUsXG4gICAgZW1pdCxcbiAgICBlbWl0dGVkXG4gIH1cbn1cblxubW9kdWxlLmV4cG9ydHMgPSBidWlsZFxuIl0sIm5hbWVzIjpbImZvcm1hdCIsInJlcXVpcmUiLCJidWlsZCIsImNvZGVzIiwiZW1pdHRlZCIsIk1hcCIsImNyZWF0ZSIsIm5hbWUiLCJjb2RlIiwibWVzc2FnZSIsIkVycm9yIiwidG9VcHBlckNhc2UiLCJ1bmRlZmluZWQiLCJidWlsZFdhcm5PcHRzIiwiYSIsImIiLCJjIiwiZm9ybWF0dGVkIiwic2V0IiwiZW1pdCIsImdldCIsIndhcm5pbmciLCJwcm9jZXNzIiwiZW1pdFdhcm5pbmciLCJtb2R1bGUiLCJleHBvcnRzIl0sInNvdXJjZVJvb3QiOiIifQ==\n//# sourceURL=webpack-internal:///(ssr)/./node_modules/process-warning/index.js\n");

/***/ })

};
;