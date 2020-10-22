import { gql } from '@apollo/client';
import * as Apollo from '@apollo/client';
export type Maybe<T> = T | null;
export type Exact<T extends { [key: string]: unknown }> = { [K in keyof T]: T[K] };
/** All built-in and custom scalars, mapped to their actual values */
export type Scalars = {
  ID: string;
  String: string;
  Boolean: boolean;
  Int: number;
  Float: number;
};

export type Mutation = {
  __typename?: 'Mutation';
  /** An example field added by the generator */
  testField: Scalars['String'];
};

export type Query = {
  __typename?: 'Query';
  /** An example field added by the generator */
  testField: Scalars['String'];
};


export const TestQueryDocument = gql`
    query TestQuery {
  testField
}
    `;

/**
 * __useTestQueryQuery__
 *
 * To run a query within a React component, call `useTestQueryQuery` and pass it any options that fit your needs.
 * When your component renders, `useTestQueryQuery` returns an object from Apollo Client that contains loading, error, and data properties
 * you can use to render your UI.
 *
 * @param baseOptions options that will be passed into the query, supported options are listed on: https://www.apollographql.com/docs/react/api/react-hooks/#options;
 *
 * @example
 * const { data, loading, error } = useTestQueryQuery({
 *   variables: {
 *   },
 * });
 */
export function useTestQueryQuery(baseOptions?: Apollo.QueryHookOptions<TestQueryQuery, TestQueryQueryVariables>) {
        return Apollo.useQuery<TestQueryQuery, TestQueryQueryVariables>(TestQueryDocument, baseOptions);
      }
export function useTestQueryLazyQuery(baseOptions?: Apollo.LazyQueryHookOptions<TestQueryQuery, TestQueryQueryVariables>) {
          return Apollo.useLazyQuery<TestQueryQuery, TestQueryQueryVariables>(TestQueryDocument, baseOptions);
        }
export type TestQueryQueryHookResult = ReturnType<typeof useTestQueryQuery>;
export type TestQueryLazyQueryHookResult = ReturnType<typeof useTestQueryLazyQuery>;
export type TestQueryQueryResult = Apollo.QueryResult<TestQueryQuery, TestQueryQueryVariables>;