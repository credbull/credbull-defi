export const getSegment = (props: any) => {
  console.log('SEGMENT=', props.children?.props?.childProp?.segment);
  // FIX (JL,2024-07-05): This deref chain always results in `undefined`. How to fix?
  return props.children?.props?.childProp?.segment;
};
