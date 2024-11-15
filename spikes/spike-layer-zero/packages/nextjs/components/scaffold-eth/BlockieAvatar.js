"use strict";
"use client";
Object.defineProperty(exports, "__esModule", { value: true });
exports.BlockieAvatar = void 0;
const blo_1 = require("blo");
// Custom Avatar for RainbowKit
const BlockieAvatar = ({ address, ensImage, size }) => (
// Don't want to use nextJS Image here (and adding remote patterns for the URL)
// eslint-disable-next-line @next/next/no-img-element
<img className="rounded-full" src={ensImage || (0, blo_1.blo)(address)} width={size} height={size} alt={`${address} avatar`}/>);
exports.BlockieAvatar = BlockieAvatar;
