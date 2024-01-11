export const anyCallHasFailed = (calls: object[]) => {
  return calls.filter((o) => 'error' in o).length > 0;
};
