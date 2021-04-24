import React, { useContext } from 'react';

export const UserAgentContext = React.createContext(null);
export function useUserAgent() {
  return useContext(UserAgentContext);
}
