"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.PaginationButton = void 0;
const outline_1 = require("@heroicons/react/24/outline");
const ITEMS_PER_PAGE = 20;
const PaginationButton = ({ currentPage, totalItems, setCurrentPage }) => {
    const isPrevButtonDisabled = currentPage === 0;
    const isNextButtonDisabled = currentPage + 1 >= Math.ceil(totalItems / ITEMS_PER_PAGE);
    const prevButtonClass = isPrevButtonDisabled ? "bg-gray-200 cursor-default" : "btn btn-primary";
    const nextButtonClass = isNextButtonDisabled ? "bg-gray-200 cursor-default" : "btn btn-primary";
    if (isNextButtonDisabled && isPrevButtonDisabled)
        return null;
    return (<div className="mt-5 justify-end flex gap-3 mx-5">
      <button className={`btn btn-sm ${prevButtonClass}`} disabled={isPrevButtonDisabled} onClick={() => setCurrentPage(currentPage - 1)}>
        <outline_1.ArrowLeftIcon className="h-4 w-4"/>
      </button>
      <span className="self-center text-primary-content font-medium">Page {currentPage + 1}</span>
      <button className={`btn btn-sm ${nextButtonClass}`} disabled={isNextButtonDisabled} onClick={() => setCurrentPage(currentPage + 1)}>
        <outline_1.ArrowRightIcon className="h-4 w-4"/>
      </button>
    </div>);
};
exports.PaginationButton = PaginationButton;
