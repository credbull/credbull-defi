"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getMetadata = void 0;
const baseUrl = process.env.VERCEL_PROJECT_PRODUCTION_URL
    ? `https://${process.env.VERCEL_PROJECT_PRODUCTION_URL}`
    : `http://localhost:${process.env.PORT || 3000}`;
const titleTemplate = "%s | Scaffold-ETH 2";
const getMetadata = ({ title, description, imageRelativePath = "/thumbnail.jpg", }) => {
    const imageUrl = `${baseUrl}${imageRelativePath}`;
    return {
        metadataBase: new URL(baseUrl),
        title: {
            default: title,
            template: titleTemplate,
        },
        description: description,
        openGraph: {
            title: {
                default: title,
                template: titleTemplate,
            },
            description: description,
            images: [
                {
                    url: imageUrl,
                },
            ],
        },
        twitter: {
            title: {
                default: title,
                template: titleTemplate,
            },
            description: description,
            images: [imageUrl],
        },
        icons: {
            icon: [{ url: "/favicon.png", sizes: "32x32", type: "image/png" }],
        },
    };
};
exports.getMetadata = getMetadata;
