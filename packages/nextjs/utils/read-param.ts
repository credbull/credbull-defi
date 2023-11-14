// Browser-based: read parameter from the URL
export const readUrlParam = (urlParamKey: string): string | null => {
  // Check if running in a browser environment
  if (typeof window !== "undefined") {
    const urlParams = new URLSearchParams(window.location.search);

    const paramValue = urlParams.get(urlParamKey);

    console.log(`Read URL Parameter with key: '${urlParamKey}', value: '${paramValue}'`);

    return paramValue;
  }

  return null;
};

// Server-based: read parameter from the Environment
export const readEnv = (envKey: string): string | undefined => {
  // Fallback to environment variable if targetNetworkKey is not set
  if (typeof process !== "undefined") {
    const envValue = process.env[envKey];

    console.log(`Read Env Variable with key: '${envKey}', value: '${envValue}'`);

    return envValue;
  }

  return undefined;
};

export const readEnvOrUrlParam = (envKey: string, urlParamKey: string): string | undefined => {
  // running in browser  - check the URL params
  const urlParamValue = readUrlParam(urlParamKey);
  if (urlParamValue) {
    return urlParamValue;
  }

  const envValue = readEnv(envKey);
  if (envValue) {
    return envValue;
  }

  return undefined;
};
