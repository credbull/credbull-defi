"use strict";
"use client";
Object.defineProperty(exports, "__esModule", { value: true });
exports.BackButton = void 0;
const navigation_1 = require("next/navigation");
const BackButton = () => {
    const router = (0, navigation_1.useRouter)();
    return (<button className="btn btn-sm btn-primary" onClick={() => router.back()}>
      Back
    </button>);
};
exports.BackButton = BackButton;
