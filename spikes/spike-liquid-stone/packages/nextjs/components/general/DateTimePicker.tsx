"use client";

import React, { useCallback, useEffect, useState } from "react";

interface DateTimePickerProps {
  selectedDate: Date | null;
  setSelectedDate: (date: Date) => void;
  setSelectedTimestamp: (timestamp: number) => void;
  resolvedTheme: string;
}

const DateTimePicker: React.FC<DateTimePickerProps> = ({
  selectedDate,
  setSelectedDate,
  setSelectedTimestamp,
  resolvedTheme,
}) => {
  const now = selectedDate || new Date();

  const [date, setDate] = useState(now.toISOString().substring(0, 10));
  const [time, setTime] = useState(now.toTimeString().substring(0, 8));

  const updateDateTime = useCallback(
    (newDate: string, newTime: string) => {
      const [hours, minutes, seconds] = newTime.split(":");
      const updatedDate = new Date(`${newDate}T${hours}:${minutes}:${seconds}`);
      setSelectedDate(updatedDate);
      setSelectedTimestamp(Math.floor(updatedDate.getTime() / 1000));
    },
    [setSelectedDate, setSelectedTimestamp],
  );

  useEffect(() => {
    if (date && time) {
      updateDateTime(date, time);
    }
  }, [date, time, updateDateTime]);

  return (
    <div className="relative">
      {/* Display selected date and time in the input */}
      <input
        type="text"
        value={selectedDate ? selectedDate.toLocaleString() : ""}
        readOnly
        className={`border ${
          resolvedTheme === "dark" ? "border-gray-700 bg-gray-700 text-white" : "border-gray-300"
        } p-2 w-full mb-4 outline-none focus:ring-0 rounded-md`}
        placeholder="Select Date and Time"
      />

      {/* Date and Time inputs */}
      <div className="flex gap-2">
        {/* Date Picker */}
        <input
          type="date"
          value={date}
          onChange={e => setDate(e.target.value)}
          className="p-2 border rounded-md mb-4 w-full"
        />

        {/* Time Picker with seconds support */}
        <input
          type="time"
          value={time}
          step="1" // Allows setting hours, minutes, and seconds
          onChange={e => setTime(e.target.value)}
          className="p-2 border rounded-md mb-4 w-full"
        />
      </div>
    </div>
  );
};

export default DateTimePicker;
