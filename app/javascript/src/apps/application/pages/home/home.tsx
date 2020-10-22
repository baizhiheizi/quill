import React from 'react';
import { TestQueryQueryHookResult, useTestQueryQuery } from '@graphql';

export function Home() {
  const { data, loading }: TestQueryQueryHookResult = useTestQueryQuery();

  if (loading) {
    return <div>loading</div>;
  }

  return <div>{data.testField}</div>;
}
