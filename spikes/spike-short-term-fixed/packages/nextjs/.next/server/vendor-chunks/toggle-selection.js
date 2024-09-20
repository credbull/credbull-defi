/*
 * ATTENTION: An "eval-source-map" devtool has been used.
 * This devtool is neither made for production nor for readable output files.
 * It uses "eval()" calls to create a separate source file with attached SourceMaps in the browser devtools.
 * If you are trying to read the output file, select a different devtool (https://webpack.js.org/configuration/devtool/)
 * or disable the default devtool with "devtool: false".
 * If you are looking for production-ready output files, see mode: "production" (https://webpack.js.org/configuration/mode/).
 */
exports.id = "vendor-chunks/toggle-selection";
exports.ids = ["vendor-chunks/toggle-selection"];
exports.modules = {

/***/ "(ssr)/./node_modules/toggle-selection/index.js":
/*!************************************************!*\
  !*** ./node_modules/toggle-selection/index.js ***!
  \************************************************/
/***/ ((module) => {

eval("module.exports = function() {\n    var selection = document.getSelection();\n    if (!selection.rangeCount) {\n        return function() {};\n    }\n    var active = document.activeElement;\n    var ranges = [];\n    for(var i = 0; i < selection.rangeCount; i++){\n        ranges.push(selection.getRangeAt(i));\n    }\n    switch(active.tagName.toUpperCase()){\n        case \"INPUT\":\n        case \"TEXTAREA\":\n            active.blur();\n            break;\n        default:\n            active = null;\n            break;\n    }\n    selection.removeAllRanges();\n    return function() {\n        selection.type === \"Caret\" && selection.removeAllRanges();\n        if (!selection.rangeCount) {\n            ranges.forEach(function(range) {\n                selection.addRange(range);\n            });\n        }\n        active && active.focus();\n    };\n};\n//# sourceURL=[module]\n//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIndlYnBhY2s6Ly9Ac2UtMi9uZXh0anMvLi9ub2RlX21vZHVsZXMvdG9nZ2xlLXNlbGVjdGlvbi9pbmRleC5qcz81YmFlIl0sInNvdXJjZXNDb250ZW50IjpbIlxubW9kdWxlLmV4cG9ydHMgPSBmdW5jdGlvbiAoKSB7XG4gIHZhciBzZWxlY3Rpb24gPSBkb2N1bWVudC5nZXRTZWxlY3Rpb24oKTtcbiAgaWYgKCFzZWxlY3Rpb24ucmFuZ2VDb3VudCkge1xuICAgIHJldHVybiBmdW5jdGlvbiAoKSB7fTtcbiAgfVxuICB2YXIgYWN0aXZlID0gZG9jdW1lbnQuYWN0aXZlRWxlbWVudDtcblxuICB2YXIgcmFuZ2VzID0gW107XG4gIGZvciAodmFyIGkgPSAwOyBpIDwgc2VsZWN0aW9uLnJhbmdlQ291bnQ7IGkrKykge1xuICAgIHJhbmdlcy5wdXNoKHNlbGVjdGlvbi5nZXRSYW5nZUF0KGkpKTtcbiAgfVxuXG4gIHN3aXRjaCAoYWN0aXZlLnRhZ05hbWUudG9VcHBlckNhc2UoKSkgeyAvLyAudG9VcHBlckNhc2UgaGFuZGxlcyBYSFRNTFxuICAgIGNhc2UgJ0lOUFVUJzpcbiAgICBjYXNlICdURVhUQVJFQSc6XG4gICAgICBhY3RpdmUuYmx1cigpO1xuICAgICAgYnJlYWs7XG5cbiAgICBkZWZhdWx0OlxuICAgICAgYWN0aXZlID0gbnVsbDtcbiAgICAgIGJyZWFrO1xuICB9XG5cbiAgc2VsZWN0aW9uLnJlbW92ZUFsbFJhbmdlcygpO1xuICByZXR1cm4gZnVuY3Rpb24gKCkge1xuICAgIHNlbGVjdGlvbi50eXBlID09PSAnQ2FyZXQnICYmXG4gICAgc2VsZWN0aW9uLnJlbW92ZUFsbFJhbmdlcygpO1xuXG4gICAgaWYgKCFzZWxlY3Rpb24ucmFuZ2VDb3VudCkge1xuICAgICAgcmFuZ2VzLmZvckVhY2goZnVuY3Rpb24ocmFuZ2UpIHtcbiAgICAgICAgc2VsZWN0aW9uLmFkZFJhbmdlKHJhbmdlKTtcbiAgICAgIH0pO1xuICAgIH1cblxuICAgIGFjdGl2ZSAmJlxuICAgIGFjdGl2ZS5mb2N1cygpO1xuICB9O1xufTtcbiJdLCJuYW1lcyI6WyJtb2R1bGUiLCJleHBvcnRzIiwic2VsZWN0aW9uIiwiZG9jdW1lbnQiLCJnZXRTZWxlY3Rpb24iLCJyYW5nZUNvdW50IiwiYWN0aXZlIiwiYWN0aXZlRWxlbWVudCIsInJhbmdlcyIsImkiLCJwdXNoIiwiZ2V0UmFuZ2VBdCIsInRhZ05hbWUiLCJ0b1VwcGVyQ2FzZSIsImJsdXIiLCJyZW1vdmVBbGxSYW5nZXMiLCJ0eXBlIiwiZm9yRWFjaCIsInJhbmdlIiwiYWRkUmFuZ2UiLCJmb2N1cyJdLCJtYXBwaW5ncyI6IkFBQ0FBLE9BQU9DLE9BQU8sR0FBRztJQUNmLElBQUlDLFlBQVlDLFNBQVNDLFlBQVk7SUFDckMsSUFBSSxDQUFDRixVQUFVRyxVQUFVLEVBQUU7UUFDekIsT0FBTyxZQUFhO0lBQ3RCO0lBQ0EsSUFBSUMsU0FBU0gsU0FBU0ksYUFBYTtJQUVuQyxJQUFJQyxTQUFTLEVBQUU7SUFDZixJQUFLLElBQUlDLElBQUksR0FBR0EsSUFBSVAsVUFBVUcsVUFBVSxFQUFFSSxJQUFLO1FBQzdDRCxPQUFPRSxJQUFJLENBQUNSLFVBQVVTLFVBQVUsQ0FBQ0Y7SUFDbkM7SUFFQSxPQUFRSCxPQUFPTSxPQUFPLENBQUNDLFdBQVc7UUFDaEMsS0FBSztRQUNMLEtBQUs7WUFDSFAsT0FBT1EsSUFBSTtZQUNYO1FBRUY7WUFDRVIsU0FBUztZQUNUO0lBQ0o7SUFFQUosVUFBVWEsZUFBZTtJQUN6QixPQUFPO1FBQ0xiLFVBQVVjLElBQUksS0FBSyxXQUNuQmQsVUFBVWEsZUFBZTtRQUV6QixJQUFJLENBQUNiLFVBQVVHLFVBQVUsRUFBRTtZQUN6QkcsT0FBT1MsT0FBTyxDQUFDLFNBQVNDLEtBQUs7Z0JBQzNCaEIsVUFBVWlCLFFBQVEsQ0FBQ0Q7WUFDckI7UUFDRjtRQUVBWixVQUNBQSxPQUFPYyxLQUFLO0lBQ2Q7QUFDRiIsImZpbGUiOiIoc3NyKS8uL25vZGVfbW9kdWxlcy90b2dnbGUtc2VsZWN0aW9uL2luZGV4LmpzIiwic291cmNlUm9vdCI6IiJ9\n//# sourceURL=webpack-internal:///(ssr)/./node_modules/toggle-selection/index.js\n");

/***/ })

};
;