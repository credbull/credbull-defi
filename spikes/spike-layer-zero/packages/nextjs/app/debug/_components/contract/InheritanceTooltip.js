"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.InheritanceTooltip = void 0;
const solid_1 = require("@heroicons/react/20/solid");
const InheritanceTooltip = ({ inheritedFrom }) => (<>
    {inheritedFrom && (<span className="tooltip tooltip-top tooltip-accent px-2 md:break-normal" data-tip={`Inherited from: ${inheritedFrom}`}>
        <solid_1.InformationCircleIcon className="h-4 w-4" aria-hidden="true"/>
      </span>)}
  </>);
exports.InheritanceTooltip = InheritanceTooltip;
