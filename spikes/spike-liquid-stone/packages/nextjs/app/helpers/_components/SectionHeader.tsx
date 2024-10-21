"use client";

const SectionHeader = ({ title }: { title: string }) => {
  return (
    <div className="section-header-wrapper mb-6">
      <h1 className="text-3xl md:text-3xl font-bold py-4">{title}</h1>
      <div className="w-full h-1 bg-gradient-to-r from-blue-400 to-blue-600 mt-1 rounded-md"></div>
    </div>
  );
};

export default SectionHeader;
