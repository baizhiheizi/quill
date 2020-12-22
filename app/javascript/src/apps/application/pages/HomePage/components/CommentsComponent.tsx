import LoadingComponent from '@application/components/LoadingComponent/LoadingComponent';
import {
  Comment as IComment,
  CommentConnectionQueryHookResult,
  useCommentConnectionQuery,
} from '@graphql';
import { MarkdownRendererComponent, useUserAgent } from '@shared';
import { Avatar, Button, Comment, List } from 'antd';
import moment from 'moment';
import React from 'react';
import { useTranslation } from 'react-i18next';
import { Link } from 'react-router-dom';

export default function CommentsComponent() {
  const { t, i18n } = useTranslation();
  const { isMobile } = useUserAgent();
  moment.locale(i18n.language);
  const {
    data,
    loading,
    fetchMore,
  }: CommentConnectionQueryHookResult = useCommentConnectionQuery();

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
                  variables: {
                    after: endCursor,
                  },
                });
              }}
            >
              {t('common.loadMore')}
            </Button>
          </div>
        )
      }
      renderItem={(comment: Partial<IComment>) => (
        <li
          id={`comment-${comment.id}`}
          className={isMobile.phone ? 'blockquote-collapsed' : ''}
        >
          {!comment.deletedAt && (
            <Comment
              className='comment-list'
              author={comment.author.name}
              avatar={
                <Avatar src={comment.author.avatarUrl}>
                  {comment.author.name[0]}
                </Avatar>
              }
              content={<MarkdownRendererComponent source={comment.content} />}
              datetime={<span>{moment(comment.createdAt).fromNow()}</span>}
              actions={[
                <span>
                  {t('commentsComponent.from')}: {` `}
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
