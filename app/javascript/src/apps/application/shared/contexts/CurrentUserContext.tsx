import React, { useContext } from 'react';

export const CurrentUserContext = React.createContext(null);
export function useCurrentUser() {
  return useContext(CurrentUserContext);
}
