import { Avatar, Comment, List } from 'antd';
import LoadingComponent from 'apps/application/components/LoadingComponent/LoadingComponent';
import LoadMoreComponent from 'apps/application/components/LoadMoreComponent/LoadMoreComponent';
import { MarkdownRendererComponent, useUserAgent } from 'apps/shared';
import {
  Comment as IComment,
  CommentConnectionQueryHookResult,
  useCommentConnectionQuery,
} from 'graphqlTypes';
import moment from 'moment';
import React from 'react';
import { useTranslation } from 'react-i18next';
import { Link } from 'react-router-dom';

export default function UserCommentsComponent(props: {
  authorMixinId: string;
}) {
  const { authorMixinId } = props;
  const { t, i18n } = useTranslation();
  const { isMobile } = useUserAgent();
  moment.locale(i18n.language);
  const { data, loading, fetchMore }: CommentConnectionQueryHookResult =
    useCommentConnectionQuery({
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
        <LoadMoreComponent
          hasNextPage={hasNextPage}
          loading={loading}
          fetchMore={() => {
            fetchMore({
              variables: {
                after: endCursor,
              },
            });
          }}
        />
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
                <Avatar src={comment.author.avatar}>
                  {comment.author.name[0]}
                </Avatar>
              }
              content={<MarkdownRendererComponent source={comment.content} />}
              datetime={<span>{moment(comment.createdAt).fromNow()}</span>}
              actions={[
                <span>
                  {t('from')}: {` `}
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
