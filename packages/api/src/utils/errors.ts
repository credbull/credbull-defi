export const anyCallHasFailed = (calls: object[]) => {
  return calls.filter((o) => 'error' in o && Boolean(o.error)).length > 0;
};
