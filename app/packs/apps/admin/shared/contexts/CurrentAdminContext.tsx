import React, { useContext } from 'react';

export const CurrentAdminContext = React.createContext(null);
export function useCurrentAdmin() {
  return useContext(CurrentAdminContext);
}
