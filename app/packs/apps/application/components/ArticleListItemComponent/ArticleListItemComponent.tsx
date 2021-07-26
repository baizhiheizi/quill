import {
  DislikeOutlined,
  DollarOutlined,
  LikeOutlined,
  MessageOutlined,
  ShareAltOutlined,
} from '@ant-design/icons';
import { Avatar, Button, List, Row, Space } from 'antd';
import { ArticleShareButton } from 'apps/application/shared';
import { Article } from 'graphqlTypes';
import moment from 'moment';
import React from 'react';
import { useTranslation } from 'react-i18next';
import { Link } from 'react-router-dom';
import ArticleTagsComponent from '../ArticleTagsComponent/ArticleTagsComponent';

export default function ArticleListItemComponent(props: {
  article: Partial<Article>;
}) {
  const { i18n } = useTranslation();
  moment.locale(i18n.language);
  const { article } = props;
  return (
    <List.Item
      style={{ padding: '1rem 0.5rem' }}
      key={article.uuid}
      actions={
        article.upvoteRatio === null
          ? [
              <RevenueAction
                revenueUsd={article.revenueUsd}
                currencySymbol={article.currency.symbol}
              />,
              <CommentsCountAction commentsCount={article.commentsCount} />,
              <ArticleShareButton article={article}>
                <Button size='small' type='text' icon={<ShareAltOutlined />} />
              </ArticleShareButton>,
            ]
          : [
              <RevenueAction
                revenueUsd={article.revenueUsd}
                currencySymbol={article.currency.symbol}
              />,
              <CommentsCountAction commentsCount={article.commentsCount} />,
              <UpdateVoteRatioAction upvoteRatio={article.upvoteRatio} />,
              <ArticleShareButton article={article}>
                <Button size='small' type='text' icon={<ShareAltOutlined />} />
              </ArticleShareButton>,
            ]
      }
    >
      <List.Item.Meta
        style={{ marginBottom: 0 }}
        avatar={
          <Link to={`/users/${article.author.mixinId}`}>
            <Avatar src={article.author.avatar}>
              {article.author.name[0]}
            </Avatar>
          </Link>
        }
        title={
          <Row>
            <div>
              <Link to={`/users/${article.author.mixinId}`}>
                {article.author.name}
              </Link>
              <div className='text-xs text-gray-500'>
                {moment(article.publishedAt).fromNow()}
              </div>
            </div>
            {article.price > 0 && (
              <div className='relative ml-auto'>
                <Space className='ml-auto'>
                  <Avatar size='small' src={article.currency.iconUrl} />
                  <span>
                    {article.currency.symbol === 'BTC'
                      ? article.price.toFixed(6)
                      : article.price.toFixed(2)}
                  </span>
                </Space>
                <div className='absolute right-0 text-xs text-gray-500'>
                  ≈ ${article.priceUsd}
                </div>
              </div>
            )}
          </Row>
        }
      />
      <Link className='block initial' to={`/articles/${article.uuid}`}>
        <div className='mb-4 font-sans text-xl font-semibold'>
          {article.title}
        </div>
        <div className='mb-4 text-base'>{article.intro}</div>
      </Link>
      <ArticleTagsComponent tags={article.tags} />
    </List.Item>
  );
}

function RevenueAction(props: { revenueUsd: number; currencySymbol: string }) {
  return (
    <Space>
      <DollarOutlined />
      <span>{props.revenueUsd.toFixed(2)}</span>
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
