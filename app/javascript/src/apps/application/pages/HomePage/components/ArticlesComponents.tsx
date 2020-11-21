import UserCardComponent from '@/apps/application/components/UserCardComponent/UserCardComponent';
import {
  DislikeOutlined,
  LikeOutlined,
  MessageOutlined,
  RiseOutlined,
  ShareAltOutlined,
} from '@ant-design/icons';
import LoadingComponent from '@application/components/LoadingComponent/LoadingComponent';
import {
  handleShare,
  PRS_ICON_URL,
  usePrsdigg,
  useUserAgent,
} from '@application/shared';
import {
  Article,
  ArticleConnectionQueryHookResult,
  useArticleConnectionQuery,
} from '@graphql';
import { Avatar, Button, List, Popover, Row, Space } from 'antd';
import moment from 'moment';
import React from 'react';
import { useTranslation } from 'react-i18next';
import { Link } from 'react-router-dom';

export default function ArticlesComponent(props: {
  order: 'default' | 'lately' | 'revenue';
}) {
  const { order } = props;
  const { mixinEnv } = useUserAgent();
  const { appId } = usePrsdigg();
  const { t, i18n } = useTranslation();
  moment.locale(i18n.language);
  const {
    data,
    loading,
    fetchMore,
  }: ArticleConnectionQueryHookResult = useArticleConnectionQuery({
    fetchPolicy: 'network-only',
    notifyOnNetworkStatusChange: true,
    variables: {
      order,
    },
  });

  if (!data && loading) {
    return <LoadingComponent />;
  }

  const {
    articleConnection: {
      nodes: articles,
      pageInfo: { hasNextPage, endCursor },
    },
  } = data;
  return (
    <List
      size='large'
      itemLayout='vertical'
      dataSource={articles}
      loadMore={
        hasNextPage && (
          <div
            style={{
              textAlign: 'center',
              marginTop: 12,
              height: 32,
              lineHeight: '32px',
            }}
          >
            <Button
              loading={loading}
              onClick={() => {
                fetchMore({
                  updateQuery: (prev, { fetchMoreResult }) => {
                    if (!fetchMoreResult) {
                      return prev;
                    }
                    const connection = fetchMoreResult.articleConnection;
                    connection.nodes = prev.articleConnection.nodes.concat(
                      connection.nodes,
                    );
                    return Object.assign({}, prev, {
                      articleConnection: connection,
                    });
                  },
                  variables: {
                    after: endCursor,
                    order,
                  },
                });
              }}
            >
              {t('common.loadMore')}
            </Button>
          </div>
        )
      }
      renderItem={(article: Partial<Article>) => (
        <List.Item
          style={{ padding: '1rem 0.5rem' }}
          key={article.uuid}
          actions={
            article.upvoteRatio === null
              ? [
                  <RevenueAction revenue={article.revenue} />,
                  <CommentsCountAction commentsCount={article.commentsCount} />,
                  <ShareAction
                    article={article}
                    mixinEnv={mixinEnv}
                    appId={appId}
                  />,
                ]
              : [
                  <RevenueAction revenue={article.revenue} />,
                  <CommentsCountAction commentsCount={article.commentsCount} />,
                  <UpdateVoteRatioAction upvoteRatio={article.upvoteRatio} />,
                  <ShareAction
                    article={article}
                    mixinEnv={mixinEnv}
                    appId={appId}
                  />,
                ]
          }
        >
          <List.Item.Meta
            style={{ marginBottom: 0 }}
            avatar={
              <Popover
                content={<UserCardComponent user={article.author} />}
                placement='bottomLeft'
              >
                <Avatar src={article.author.avatarUrl}>
                  {article.author.name[0]}
                </Avatar>
              </Popover>
            }
            title={
              <Row>
                <div>
                  <div>{article.author.name}</div>
                  <div style={{ fontSize: '0.8rem', color: '#aaa' }}>
                    {moment(article.createdAt).fromNow()}
                  </div>
                </div>
                <Space style={{ marginLeft: 'auto' }}>
                  <Avatar size='small' src={PRS_ICON_URL} />
                  <span>{article.price.toFixed(2)}</span>
                </Space>
              </Row>
            }
          />
          <Link style={{ color: 'initial' }} to={`/articles/${article.uuid}`}>
            <h2>{article.title}</h2>
            <p>{article.intro}</p>
          </Link>
        </List.Item>
      )}
    />
  );
}

function RevenueAction(props: { revenue: number }) {
  return (
    <Space>
      <RiseOutlined />
      <span>{props.revenue.toFixed(2)}</span>
    </Space>
  );
}

function CommentsCountAction(props: { commentsCount: number }) {
  return (
    <Space>
      <MessageOutlined />
      <span>{props.commentsCount}</span>
    </Space>
  );
}
function UpdateVoteRatioAction(props: { upvoteRatio: number }) {
  const { upvoteRatio } = props;
  return (
    <Space
      style={upvoteRatio >= 50 ? { color: '#1890ff' } : { color: '#ff4d4f' }}
    >
      {upvoteRatio >= 50 ? <LikeOutlined /> : <DislikeOutlined />}
      <span>{upvoteRatio === null ? '' : `${upvoteRatio}%`}</span>
    </Space>
  );
}

function ShareAction(props: {
  article: Partial<Article>;
  mixinEnv: boolean;
  appId: string;
}) {
  return (
    <Button
      size='small'
      type='text'
      icon={
        <ShareAltOutlined
          onClick={() => {
            handleShare(props.article, Boolean(props.mixinEnv), props.appId);
          }}
        />
      }
    />
  );
}
