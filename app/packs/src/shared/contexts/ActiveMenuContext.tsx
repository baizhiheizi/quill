import React, { useContext } from 'react';

export const ActiveMenuContext = React.createContext(null);
export function useActiveMenu() {
  return useContext(ActiveMenuContext);
}
