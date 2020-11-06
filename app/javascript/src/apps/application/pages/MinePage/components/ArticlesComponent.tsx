import LoadingComponent from '@application/components/LoadingComponent/LoadingComponent';
import {
  Article,
  HideArticleMutationHookResult,
  MyArticleConnectionQueryHookResult,
  PublishArticleMutationHookResult,
  useHideArticleMutation,
  useMyArticleConnectionQuery,
  usePublishArticleMutation,
} from '@graphql';
import {
  Avatar,
  Button,
  List,
  message,
  Popconfirm,
  Row,
  Space,
  Tag,
} from 'antd';
import moment from 'moment';
import React from 'react';
import { Link } from 'react-router-dom';
moment.locale('zh-cn');

export default function ArticlesComponent(props: {
  type: 'author' | 'reader';
}) {
  const { type } = props;
  const {
    data,
    loading,
    fetchMore,
    refetch,
  }: MyArticleConnectionQueryHookResult = useMyArticleConnectionQuery({
    variables: { type },
  });
  const [
    hideArticle,
    { loading: hiding },
  ]: HideArticleMutationHookResult = useHideArticleMutation({
    update(_, { data: { error: err } }) {
      if (err) {
        message.error(err);
      } else {
        message.success('文章已隐藏');
        refetch();
      }
    },
  });
  const [
    publishArticle,
    { loading: publishing },
  ]: PublishArticleMutationHookResult = usePublishArticleMutation({
    update(_, { data: { error: err } }) {
      if (err) {
        message.error(err);
      } else {
        message.success('文章已公开');
        refetch();
      }
    },
  });

  if (loading) {
    return <LoadingComponent />;
  }

  const {
    myArticleConnection: {
      nodes: articles,
      pageInfo: { hasNextPage, endCursor },
    },
  } = data;

  return (
    <List
      size='small'
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
                    const connection = fetchMoreResult.myArticleConnection;
                    connection.nodes = prev.myArticleConnection.nodes.concat(
                      connection.nodes,
                    );
                    return Object.assign({}, prev, {
                      myArticleConnection: connection,
                    });
                  },
                  variables: {
                    after: endCursor,
                    type,
                  },
                });
              }}
            >
              加载更多
            </Button>
          </div>
        )
      }
      renderItem={(article: Partial<Article>) => (
        <List.Item
          key={article.uuid}
          actions={
            type === 'author' &&
            (article.state === 'blocked'
              ? [<Link to={`/articles/${article.uuid}`}>查看</Link>]
              : [
                  <Link to={`/articles/${article.uuid}`}>查看</Link>,
                  <span>
                    {article.state === 'hidden' ? (
                      <Popconfirm
                        title='确定要将文章公开吗？'
                        disabled={publishing}
                        onConfirm={() =>
                          publishArticle({
                            variables: { input: { uuid: article.uuid } },
                          })
                        }
                      >
                        <a>公开</a>
                      </Popconfirm>
                    ) : (
                      <Popconfirm
                        title='确定要将文章隐藏吗？已购读者将不受影响。'
                        disabled={hiding}
                        onConfirm={() =>
                          hideArticle({
                            variables: { input: { uuid: article.uuid } },
                          })
                        }
                      >
                        <a>隐藏</a>
                      </Popconfirm>
                    )}
                  </span>,
                  <Link to={`/articles/${article.uuid}/edit`}>编辑</Link>,
                ])
          }
        >
          <List.Item.Meta
            style={{ marginBottom: 0 }}
            avatar={<Avatar src={article.author.avatarUrl} />}
            title={
              <Row>
                <div>
                  <div>{article.author.name}</div>
                  <div style={{ fontSize: '0.8rem', color: '#aaa' }}>
                    {moment(article.createdAt).fromNow()}
                  </div>
                </div>
              </Row>
            }
          />
          <h3>
            <Space>
              {type === 'author' && article.state === 'published' && (
                <Tag color='success'>已发布</Tag>
              )}
              {type === 'author' && article.state === 'blocked' && (
                <Tag color='error'>已屏蔽</Tag>
              )}
              {type === 'author' && article.state === 'hidden' && (
                <Tag color='warning'>已隐藏</Tag>
              )}
              {type === 'author' ? (
                article.title
              ) : (
                <Link
                  style={{ color: 'inherit' }}
                  to={`/articles/${article.uuid}`}
                >
                  {article.title}
                </Link>
              )}
            </Space>
          </h3>
        </List.Item>
      )}
    />
  );
}
