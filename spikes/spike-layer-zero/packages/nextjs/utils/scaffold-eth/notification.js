"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.notification = void 0;
const react_1 = __importDefault(require("react"));
const react_hot_toast_1 = require("react-hot-toast");
const solid_1 = require("@heroicons/react/20/solid");
const solid_2 = require("@heroicons/react/24/solid");
const ENUM_STATUSES = {
    success: <solid_2.CheckCircleIcon className="w-7 text-success"/>,
    loading: <span className="w-6 loading loading-spinner"></span>,
    error: <solid_2.ExclamationCircleIcon className="w-7 text-error"/>,
    info: <solid_2.InformationCircleIcon className="w-7 text-info"/>,
    warning: <solid_2.ExclamationTriangleIcon className="w-7 text-warning"/>,
};
const DEFAULT_DURATION = 3000;
const DEFAULT_POSITION = "top-center";
/**
 * Custom Notification
 */
const Notification = ({ content, status, duration = DEFAULT_DURATION, icon, position = DEFAULT_POSITION, }) => {
    return react_hot_toast_1.toast.custom(t => (<div className={`flex flex-row items-start justify-between max-w-sm rounded-xl shadow-center shadow-accent bg-base-200 p-4 transform-gpu relative transition-all duration-500 ease-in-out space-x-2
        ${position.substring(0, 3) == "top"
            ? `hover:translate-y-1 ${t.visible ? "top-0" : "-top-96"}`
            : `hover:-translate-y-1 ${t.visible ? "bottom-0" : "-bottom-96"}`}`}>
        <div className="leading-[0] self-center">{icon ? icon : ENUM_STATUSES[status]}</div>
        <div className={`overflow-x-hidden break-words whitespace-pre-line ${icon ? "mt-1" : ""}`}>{content}</div>

        <div className={`cursor-pointer text-lg ${icon ? "mt-1" : ""}`} onClick={() => react_hot_toast_1.toast.dismiss(t.id)}>
          <solid_1.XMarkIcon className="w-6 cursor-pointer" onClick={() => react_hot_toast_1.toast.remove(t.id)}/>
        </div>
      </div>), {
        duration: status === "loading" ? Infinity : duration,
        position,
    });
};
exports.notification = {
    success: (content, options) => {
        return Notification(Object.assign({ content, status: "success" }, options));
    },
    info: (content, options) => {
        return Notification(Object.assign({ content, status: "info" }, options));
    },
    warning: (content, options) => {
        return Notification(Object.assign({ content, status: "warning" }, options));
    },
    error: (content, options) => {
        return Notification(Object.assign({ content, status: "error" }, options));
    },
    loading: (content, options) => {
        return Notification(Object.assign({ content, status: "loading" }, options));
    },
    remove: (toastId) => {
        react_hot_toast_1.toast.remove(toastId);
    },
};
