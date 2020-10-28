import { ApolloClient, InMemoryCache } from '@apollo/client';

export const apolloClient = (uri: string, csrfToken: string) =>
  new ApolloClient({
    uri,
    cache: new InMemoryCache(),
    credentials: 'same-origin',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': csrfToken,
    },
  });
