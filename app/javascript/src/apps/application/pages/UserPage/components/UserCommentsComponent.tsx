import LoadingComponent from '@application/components/LoadingComponent/LoadingComponent';
import {
  Comment as IComment,
  CommentConnectionQueryHookResult,
  useCommentConnectionQuery,
} from '@graphql';
import Editor from '@uiw/react-md-editor';
import { Avatar, Button, Comment, List } from 'antd';
import moment from 'moment';
import React from 'react';
import { Link } from 'react-router-dom';
moment.locale('zh-cn');

export default function UserCommentsComponent(props: {
  authorMixinId: string;
}) {
  const { authorMixinId } = props;
  const {
    data,
    loading,
    fetchMore,
  }: CommentConnectionQueryHookResult = useCommentConnectionQuery({
    variables: { authorMixinId },
  });

  if (loading) {
    return <LoadingComponent />;
  }

  const {
    commentConnection: {
      nodes: comments,
      pageInfo: { hasNextPage, endCursor },
    },
  } = data;

  return (
    <List
      dataSource={comments}
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
              type='link'
              onClick={() => {
                fetchMore({
                  updateQuery: (prev, { fetchMoreResult }) => {
                    if (!fetchMoreResult) {
                      return prev;
                    }
                    const connection = fetchMoreResult.commentConnection;
                    connection.nodes = prev.commentConnection.nodes.concat(
                      connection.nodes,
                    );
                    return Object.assign({}, prev, {
                      commentConnection: connection,
                    });
                  },
                  variables: {
                    after: endCursor,
                  },
                });
              }}
            >
              加载更多
            </Button>
          </div>
        )
      }
      renderItem={(comment: Partial<IComment>) => (
        <li>
          {!comment.deletedAt && (
            <Comment
              className='comment-list'
              author={comment.author.name}
              avatar={
                <Avatar src={comment.author.avatarUrl}>
                  {comment.author.name[0]}
                </Avatar>
              }
              content={<Editor.Markdown source={comment.content} />}
              datetime={<span>{moment(comment.createdAt).fromNow()}</span>}
              actions={[
                <span>
                  来自: {` `}
                  <Link
                    style={{ color: 'inherit' }}
                    to={`/articles/${comment.commentable.uuid}`}
                  >
                    {comment.commentable.title}
                  </Link>
                </span>,
              ]}
            />
          )}
        </li>
      )}
    />
  );
}
