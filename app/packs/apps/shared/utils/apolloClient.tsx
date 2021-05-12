import { ApolloClient, InMemoryCache } from '@apollo/client';

const customizedConnectionMergeFunction = (
  keyArgs: false | string[] = false,
): {
  keyArgs: any;
  merge: (existing: any, incoming: any, options?: any) => any;
} => {
  return {
    keyArgs,
    merge(existing: any, incoming: any, { args }) {
      if (args?.after === existing?.pageInfo?.endCursor) {
        const nodes = existing ? [...existing.nodes] : [];
        return {
          ...incoming,
          nodes: [...nodes, ...incoming.nodes],
        };
      } else {
        return incoming;
      }
    },
  };
};

export const apolloClient = (uri: string, csrfToken?: string) => {
  const cache = new InMemoryCache({
    typePolicies: {
      Query: {
        fields: {
          adminAnnouncementConnection: customizedConnectionMergeFunction(),
          adminArticleConnection: customizedConnectionMergeFunction([
            'query',
            'state',
          ]),
          adminArticleSnapshotConnection: customizedConnectionMergeFunction([
            'articleUuid',
          ]),
          adminBonusConnection: customizedConnectionMergeFunction(),
          adminMixinMessageConnection: customizedConnectionMergeFunction(),
          adminMixinNetworkSnapshotConnection:
            customizedConnectionMergeFunction(['filter', 'userId']),
          adminOrderConnection: customizedConnectionMergeFunction([
            'itemId',
            'itemType',
          ]),
          adminPaymentConnection: customizedConnectionMergeFunction(),
          adminPrsAccountConnection: customizedConnectionMergeFunction([
            'query',
            'status',
          ]),
          adminPrsTransactionConnection: customizedConnectionMergeFunction([
            'type',
          ]),
          adminSwapOrderConnection: customizedConnectionMergeFunction(),
          adminTransferConnection: customizedConnectionMergeFunction([
            'itemId',
            'itemType',
            'sourceId',
            'sourceType',
          ]),
          adminUserConnection: customizedConnectionMergeFunction([
            'filter',
            'query',
            'orderBy',
          ]),
          articleConnection: customizedConnectionMergeFunction([
            'tagId',
            'order',
            'query',
          ]),
          commentConnection: customizedConnectionMergeFunction([
            'commentableId',
            'commentableType',
            'authorMixinId',
            'orderBy',
          ]),
          myAccessTokenConnection: customizedConnectionMergeFunction(),
          myAuthoringSubscriptionConnection:
            customizedConnectionMergeFunction(),
          myReadingSubscriptionConnection: customizedConnectionMergeFunction(),
          myCommentingSubscriptionConnection:
            customizedConnectionMergeFunction(),
          myNotificationConnection: customizedConnectionMergeFunction(),
          myTransferConnection: customizedConnectionMergeFunction([
            'transferType',
          ]),
          myArticleOrderConnection: customizedConnectionMergeFunction([
            'uuid',
            'orderType',
          ]),
          mySwapOrderConnection: customizedConnectionMergeFunction(),
          myPaymentConnection: customizedConnectionMergeFunction(),
          myArticleConnection: customizedConnectionMergeFunction([
            'type',
            'state',
          ]),
          userArticleConnection: customizedConnectionMergeFunction([
            'type',
            'mixinId',
          ]),
          tagConnection: customizedConnectionMergeFunction(),
          transferConnection: customizedConnectionMergeFunction(),
        },
      },
    },
  });

  return new ApolloClient({
    uri,
    cache,
    credentials: 'same-origin',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token':
        csrfToken ||
        ((document.querySelector("meta[name='csrf-token']") as any) || {})
          .content,
    },
  });
};
