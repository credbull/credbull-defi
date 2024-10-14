import React from 'react';
import { MAX_PERIOD } from '~~/lib/constants';

const PeriodButtons: React.FC = () => {
  return (
    <div className="flex flex-wrap">
      {Array.from({ length: MAX_PERIOD + 1 }, (_, index) => (
        <button key={index} className="btn rounded-none">
          {index}
        </button>
      ))}
    </div>
  );
};

export default PeriodButtons;