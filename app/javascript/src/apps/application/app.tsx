import { Button } from 'antd';
import React from 'react';
import { apolloClient } from '@shared';
import { ApolloProvider } from '@apollo/client';

export default function App(props: { csrfToken: string }) {
  const { csrfToken } = props;
  return (
    <ApolloProvider client={apolloClient('/graphql', csrfToken)}>
      <div>
        hello world, <Button>Antd Button</Button>
      </div>
    </ApolloProvider>
  );
}
