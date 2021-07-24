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
            'authorMixinUuid',
          ]),
          adminArticleSnapshotConnection: customizedConnectionMergeFunction([
            'articleUuid',
            'state',
            'query',
          ]),
          adminCommentConnection: customizedConnectionMergeFunction([
            'commentableId',
            'commentableType',
            'authorMixinUuid',
          ]),
          adminBonusConnection: customizedConnectionMergeFunction(),
          adminDailyStatisticConnection: customizedConnectionMergeFunction([
            'startDate',
            'endDate',
          ]),
          adminMixinMessageConnection: customizedConnectionMergeFunction(),
          adminMixinNetworkSnapshotConnection:
            customizedConnectionMergeFunction(['filter', 'userId']),
          adminOrderConnection: customizedConnectionMergeFunction([
            'state',
            'itemId',
            'itemType',
          ]),
          adminPaymentConnection: customizedConnectionMergeFunction([
            'state',
            'payerMixinUuid',
          ]),
          adminPrsAccountConnection: customizedConnectionMergeFunction([
            'query',
            'status',
          ]),
          adminPrsTransactionConnection: customizedConnectionMergeFunction([
            'type',
          ]),
          adminSwapOrderConnection: customizedConnectionMergeFunction([
            'state',
            'payerMixinUuid',
          ]),
          adminTransferConnection: customizedConnectionMergeFunction([
            'itemId',
            'itemType',
            'sourceId',
            'sourceType',
            'transferType',
          ]),
          adminUserConnection: customizedConnectionMergeFunction([
            'filter',
            'query',
            'orderBy',
          ]),
          articleConnection: customizedConnectionMergeFunction([
            'tagId',
            'filter',
            'query',
            'timeRange',
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
            'query',
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
