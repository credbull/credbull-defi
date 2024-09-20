"use strict";
/*
 * ATTENTION: An "eval-source-map" devtool has been used.
 * This devtool is neither made for production nor for readable output files.
 * It uses "eval()" calls to create a separate source file with attached SourceMaps in the browser devtools.
 * If you are trying to read the output file, select a different devtool (https://webpack.js.org/configuration/devtool/)
 * or disable the default devtool with "devtool: false".
 * If you are looking for production-ready output files, see mode: "production" (https://webpack.js.org/configuration/mode/).
 */
exports.id = "vendor-chunks/split-on-first";
exports.ids = ["vendor-chunks/split-on-first"];
exports.modules = {

/***/ "(ssr)/./node_modules/split-on-first/index.js":
/*!**********************************************!*\
  !*** ./node_modules/split-on-first/index.js ***!
  \**********************************************/
/***/ ((module) => {

eval("\nmodule.exports = (string, separator)=>{\n    if (!(typeof string === \"string\" && typeof separator === \"string\")) {\n        throw new TypeError(\"Expected the arguments to be of type `string`\");\n    }\n    if (separator === \"\") {\n        return [\n            string\n        ];\n    }\n    const separatorIndex = string.indexOf(separator);\n    if (separatorIndex === -1) {\n        return [\n            string\n        ];\n    }\n    return [\n        string.slice(0, separatorIndex),\n        string.slice(separatorIndex + separator.length)\n    ];\n};\n//# sourceURL=[module]\n//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiKHNzcikvLi9ub2RlX21vZHVsZXMvc3BsaXQtb24tZmlyc3QvaW5kZXguanMiLCJtYXBwaW5ncyI6IkFBQUE7QUFFQUEsT0FBT0MsT0FBTyxHQUFHLENBQUNDLFFBQVFDO0lBQ3pCLElBQUksQ0FBRSxRQUFPRCxXQUFXLFlBQVksT0FBT0MsY0FBYyxRQUFPLEdBQUk7UUFDbkUsTUFBTSxJQUFJQyxVQUFVO0lBQ3JCO0lBRUEsSUFBSUQsY0FBYyxJQUFJO1FBQ3JCLE9BQU87WUFBQ0Q7U0FBTztJQUNoQjtJQUVBLE1BQU1HLGlCQUFpQkgsT0FBT0ksT0FBTyxDQUFDSDtJQUV0QyxJQUFJRSxtQkFBbUIsQ0FBQyxHQUFHO1FBQzFCLE9BQU87WUFBQ0g7U0FBTztJQUNoQjtJQUVBLE9BQU87UUFDTkEsT0FBT0ssS0FBSyxDQUFDLEdBQUdGO1FBQ2hCSCxPQUFPSyxLQUFLLENBQUNGLGlCQUFpQkYsVUFBVUssTUFBTTtLQUM5QztBQUNGIiwic291cmNlcyI6WyJ3ZWJwYWNrOi8vQHNlLTIvbmV4dGpzLy4vbm9kZV9tb2R1bGVzL3NwbGl0LW9uLWZpcnN0L2luZGV4LmpzPzk0NTEiXSwic291cmNlc0NvbnRlbnQiOlsiJ3VzZSBzdHJpY3QnO1xuXG5tb2R1bGUuZXhwb3J0cyA9IChzdHJpbmcsIHNlcGFyYXRvcikgPT4ge1xuXHRpZiAoISh0eXBlb2Ygc3RyaW5nID09PSAnc3RyaW5nJyAmJiB0eXBlb2Ygc2VwYXJhdG9yID09PSAnc3RyaW5nJykpIHtcblx0XHR0aHJvdyBuZXcgVHlwZUVycm9yKCdFeHBlY3RlZCB0aGUgYXJndW1lbnRzIHRvIGJlIG9mIHR5cGUgYHN0cmluZ2AnKTtcblx0fVxuXG5cdGlmIChzZXBhcmF0b3IgPT09ICcnKSB7XG5cdFx0cmV0dXJuIFtzdHJpbmddO1xuXHR9XG5cblx0Y29uc3Qgc2VwYXJhdG9ySW5kZXggPSBzdHJpbmcuaW5kZXhPZihzZXBhcmF0b3IpO1xuXG5cdGlmIChzZXBhcmF0b3JJbmRleCA9PT0gLTEpIHtcblx0XHRyZXR1cm4gW3N0cmluZ107XG5cdH1cblxuXHRyZXR1cm4gW1xuXHRcdHN0cmluZy5zbGljZSgwLCBzZXBhcmF0b3JJbmRleCksXG5cdFx0c3RyaW5nLnNsaWNlKHNlcGFyYXRvckluZGV4ICsgc2VwYXJhdG9yLmxlbmd0aClcblx0XTtcbn07XG4iXSwibmFtZXMiOlsibW9kdWxlIiwiZXhwb3J0cyIsInN0cmluZyIsInNlcGFyYXRvciIsIlR5cGVFcnJvciIsInNlcGFyYXRvckluZGV4IiwiaW5kZXhPZiIsInNsaWNlIiwibGVuZ3RoIl0sInNvdXJjZVJvb3QiOiIifQ==\n//# sourceURL=webpack-internal:///(ssr)/./node_modules/split-on-first/index.js\n");

/***/ })

};
;