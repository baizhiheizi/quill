import {
  DislikeOutlined,
  HeartOutlined,
  LikeOutlined,
  LinkOutlined,
  ShareAltOutlined,
} from '@ant-design/icons';
import {
  Alert,
  Button,
  Card,
  Col,
  Collapse,
  Divider,
  message,
  Progress,
  Row,
  Statistic,
} from 'antd';
import CommentsComponent from 'apps/application/components/CommentsComponent/CommentsComponent';
import LoadingComponent from 'apps/application/components/LoadingComponent/LoadingComponent';
import LoginModalComponent from 'apps/application/components/LoginModalComponent/LoginModalComponent';
import UserCardComponent from 'apps/application/components/UserCardComponent/UserCardComponent';
import {
  ArticleShareButton,
  CHINESE_MIXIN_GROUP_APP_ID,
  CHINESE_MIXIN_GROUP_AVATAR_URL,
  CHINESE_MIXIN_GROUP_CODE_ID,
  CHINESE_MIXIN_GROUP_DESCRIPTION,
} from 'apps/application/shared';
import {
  MarkdownRendererComponent,
  useCurrentUser,
  usePrsdigg,
  useUserAgent,
} from 'apps/shared';
import {
  ArticleQueryHookResult,
  useArticleQuery,
  useDownvoteArticleMutation,
  User,
  useToggleAuthoringSubscribeUserActionMutation,
  useUpvoteArticleMutation,
} from 'graphqlTypes';
import moment from 'moment';
import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Link, useParams } from 'react-router-dom';
import ArticleTagsComponent from '../../components/ArticleTagsComponent/ArticleTagsComponent';
import NotFoundPage from '../NotFoundPage/NotFoundPage';
import PayModalComponent from './components/PayModalComponent';
import RewardModalComponent from './components/RewardModalComponent';

export default function ArticlePage() {
  const { t, i18n } = useTranslation();
  const { uuid } = useParams<{ uuid: string }>();
  const [rewardModalVisible, setRewardModalVisible] = useState(false);
  const [payModalVisible, setPayModalVisible] = useState(false);
  const { pageTitle } = usePrsdigg();
  const { mixinEnv } = useUserAgent();
  const { currentUser } = useCurrentUser();
  const { loading, data, refetch }: ArticleQueryHookResult = useArticleQuery({
    variables: { uuid },
  });
  const [upvoteArticle] = useUpvoteArticleMutation();
  const [downvoteArticle] = useDownvoteArticleMutation();
  const [toggleAuthoringSubscribeUserAction] =
    useToggleAuthoringSubscribeUserActionMutation({
      update(
        _,
        {
          data: {
            toggleAuthoringSubscribeUserAction: { error },
          },
        },
      ) {
        if (error) {
          message.error(error);
        } else {
          message.success(
            article.author.authoringSubscribed
              ? t('success_unsubscribed')
              : t('success_subscribed'),
          );
          refetch();
        }
      },
    });

  useEffect(() => {
    return () => (document.title = pageTitle);
  }, [uuid]);

  if (loading) {
    return <LoadingComponent />;
  }

  const { article, swappableCurrencies } = data;

  if (!article) {
    return <NotFoundPage />;
  }

  document.title = `${article.title} - ${article.author.name}`;

  return (
    <div className='max-w-3xl mx-auto'>
      <div className='mb-4 font-sans text-2xl font-semibold'>
        {article.title}
      </div>
      <div className='flex flex-wrap items-center mb-4 text-gray-500 space-x-2'>
        <Link
          className='flex items-center space-x-2'
          to={`/users/${article.author.mixinId}`}
        >
          <img className='w-6 h-6 rounded-full' src={article.author.avatar} />
          <span>{article.author.name}</span>
        </Link>
        <span>{moment(article.publishedAt).format('YYYY/MM/DD HH:mm')}</span>
        {currentUser?.mixinId !== article.author.mixinId &&
          !article.author.authoringSubscribed &&
          (currentUser ? (
            <Button
              type='primary'
              shape='round'
              size='small'
              onClick={() => {
                toggleAuthoringSubscribeUserAction({
                  variables: { input: { mixinId: article.author.mixinId } },
                });
              }}
            >
              {t('subscribe')}
            </Button>
          ) : (
            <LoginModalComponent>
              <Button type='primary' shape='round' size='small'>
                {t('subscribe')}
              </Button>
            </LoginModalComponent>
          ))}
      </div>
      <div className='p-2 mb-4 overflow-hidden bg-gray-100 border-l-4 border-gray-300 overflow-ellipsis'>
        {article.intro}
      </div>
      <div style={{ marginBottom: 20 }}>
        {article.authorized ? (
          <MarkdownRendererComponent source={article.content} />
        ) : (
          <div className='text-center'>
            <div className='mb-4 text-left text-gray-500'>
              {t('article.words_count')}: {article.wordsCount}
            </div>
            {article.partialContent && (
              <div className='mb-4 text-left'>
                <MarkdownRendererComponent source={article.partialContent} />
                <div className='mt-4 text-center text-red-500'>
                  - {t('more_to_read')} -
                </div>
              </div>
            )}
            <div className='mb-4'>
              <div>
                {t('pay')}{' '}
                <span className='text-red-500'>
                  {article.price} {article.currency.symbol}
                </span>
                {` (≈$${article.priceUsd}) `}
                {t('to_continue_reading')}
              </div>
              <div>
                {t('and_receive_early_reader_revenue')} (
                <Link to='/rules'>{t('rules')}</Link>)
              </div>
            </div>
            <div className='mb-4'>
              <Alert type='warning' message={t('pay_warning')} />
            </div>
            {currentUser ? (
              <div>
                <Button type='primary' onClick={() => setPayModalVisible(true)}>
                  {article.readers.totalCount === 0
                    ? t('be_the_first_reader')
                    : t('pay_to_read')}
                </Button>
                {payModalVisible && (
                  <PayModalComponent
                    visible={payModalVisible}
                    price={article.price}
                    walletId={article.walletId}
                    articleUuid={article.uuid}
                    articleAssetId={article.assetId}
                    paymentTraceId={article.paymentTraceId}
                    swappableCurrencies={swappableCurrencies}
                    articleCurrency={article.currency}
                    swappable={article.swappable}
                    onCancel={() => {
                      setPayModalVisible(false);
                      refetch();
                    }}
                  />
                )}
                <div className='mt-4 text-sm text-black text-opacity-30'>
                  {t('already_paid')}? {t('try_to')}{' '}
                  <a onClick={() => refetch()}>{t('refresh')}</a>
                </div>
                {article.swappable && (
                  <div className='mt-2 text-sm text-black text-opacity-30'>
                    {t('pay_via_swap_tips')}
                  </div>
                )}
              </div>
            ) : (
              <LoginModalComponent>
                <Button type='primary'>{t('connect_wallet')}</Button>
              </LoginModalComponent>
            )}
          </div>
        )}
      </div>

      <div className='mb-6'>
        <ArticleTagsComponent tags={article.tags} />
      </div>

      <div className='flex items-center justify-end mb-4 text-center'>
        {article.signatureUrl && (
          <Button
            type='link'
            href={article.signatureUrl}
            target='_blank'
            icon={<LinkOutlined />}
          >
            {t('signature')}
          </Button>
        )}
        <ArticleShareButton article={article}>
          <Button type='link' icon={<ShareAltOutlined />}>
            {t('share')}
          </Button>
        </ArticleShareButton>
      </div>

      {article.articleReferences.length > 0 && (
        <div className='mb-4 border rounded'>
          <Collapse
            defaultActiveKey={['article_references', 'article_citers']}
            ghost
          >
            <Collapse.Panel
              key='article_references'
              header={t('article_references')}
            >
              {article.articleReferences.map((articleReference) => (
                <div
                  key={articleReference.reference.uuid}
                  className='flex flex-wrap items-center py-1'
                >
                  <img
                    className='w-6 h-6 mr-2 rounded-full'
                    src={articleReference.reference.author.avatar}
                  />
                  <span className='mr-2'>
                    {articleReference.reference.author.name}:
                  </span>
                  <a
                    href={`/articles/${articleReference.reference.uuid}`}
                    target='_blank'
                  >
                    {articleReference.reference.title}
                  </a>
                  <div className='ml-auto text-blue-500'>
                    {articleReference.revenueRatio * 100}%
                  </div>
                </div>
              ))}
            </Collapse.Panel>
          </Collapse>
        </div>
      )}
      {article.citers.length > 0 && (
        <div className='mb-4 border rounded'>
          <Collapse
            defaultActiveKey={['article_references', 'article_citers']}
            ghost
          >
            <Collapse.Panel key='article_citers' header={t('referenced_by')}>
              {article.citers.map((citer) => (
                <div
                  key={citer.uuid}
                  className='flex flex-wrap items-center py-1'
                >
                  <img
                    className='w-6 h-6 mr-2 rounded-full'
                    src={citer.author.avatar}
                  />
                  <span className='mr-2'>{citer.author.name}:</span>
                  <a href={`/articles/${citer.uuid}`} target='_blank'>
                    {citer.title}
                  </a>
                </div>
              ))}
            </Collapse.Panel>
          </Collapse>
        </div>
      )}

      <div className='mb-6'>
        <UserCardComponent user={article.author} />
      </div>

      <div className='mb-6'>
        <Row justify='center'>
          <Col>
            {article.authorized &&
            currentUser &&
            currentUser.mixinId !== article.author.mixinId ? (
              <Button
                type={article.upvoted ? 'primary' : 'default'}
                size='large'
                shape='circle'
                icon={<LikeOutlined />}
                onClick={() => {
                  if (!article.upvoted) {
                    upvoteArticle({
                      variables: { input: { uuid: article.uuid } },
                    });
                  }
                }}
              />
            ) : (
              <Button
                type='primary'
                size='large'
                shape='circle'
                icon={<LikeOutlined />}
              />
            )}
          </Col>
          <Col
            style={{
              marginTop: 10,
              minWidth: 100,
              padding: '0 20px',
              textAlign: 'center',
            }}
          >
            <Progress
              showInfo={false}
              percent={
                (article.upvotesCount /
                  (article.upvotesCount + article.downvotesCount)) *
                100
              }
              strokeColor='#1890ff'
              trailColor={
                article.upvotesCount + article.downvotesCount > 0
                  ? '#ff4d4f'
                  : null
              }
            />
            <div>
              {article.upvotesCount}:{article.downvotesCount}
            </div>
          </Col>
          <Col>
            {article.authorized &&
            currentUser &&
            currentUser.mixinId !== article.author.mixinId ? (
              <Button
                type={article.downvoted ? 'primary' : 'default'}
                danger={article.downvoted}
                size='large'
                shape='circle'
                icon={<DislikeOutlined />}
                onClick={() => {
                  if (!article.downvoted) {
                    downvoteArticle({
                      variables: { input: { uuid: article.uuid } },
                    });
                  }
                }}
              />
            ) : (
              <Button
                type='primary'
                size='large'
                danger
                shape='circle'
                icon={<DislikeOutlined />}
              />
            )}
          </Col>
        </Row>
      </div>
      {article.authorized && article.author.mixinId !== currentUser?.mixinId && (
        <div style={{ marginBottom: '1rem' }}>
          <div style={{ textAlign: 'center' }}>
            {currentUser ? (
              <Button
                onClick={() => setRewardModalVisible(true)}
                shape='round'
                type='primary'
                size='large'
                danger
              >
                <HeartOutlined /> {t('reward')}
              </Button>
            ) : (
              <LoginModalComponent>
                <Button shape='round' type='primary' size='large' danger>
                  <HeartOutlined /> {t('reward')}
                </Button>
              </LoginModalComponent>
            )}
            {rewardModalVisible && (
              <RewardModalComponent
                visible={rewardModalVisible}
                articleUuid={uuid}
                articleAssetId={article.assetId}
                swappableCurrencies={swappableCurrencies}
                articleCurrency={article.currency}
                swappable={article.swappable}
                onCancel={() => {
                  setRewardModalVisible(false);
                  refetch();
                }}
                walletId={article.walletId}
              />
            )}
          </div>
        </div>
      )}
      {article.readers.totalCount > 0 && (
        <div>
          <Row justify='center'>
            <Col>
              <h4>
                {article.price > 0 && (
                  <>
                    <span className='text-red-500'>
                      {article.buyOrders.totalCount}
                    </span>{' '}
                    {t('times_bought')},{' '}
                  </>
                )}
                <span className='text-red-500'>
                  {article.rewardOrders.totalCount}
                </span>{' '}
                {t('times_reward')}
              </h4>
            </Col>
          </Row>
          <div className='w-full mb-4'>
            <div
              className={`m-auto w-72 ${
                article.randomReaders.length < 8
                  ? 'flex justify-center'
                  : 'grid grid-cols-8 '
              }`}
            >
              {article.randomReaders.map((reader: Partial<User>) => (
                <img
                  className='w-8  h-8 rounded-full m-0.5'
                  key={reader.mixinId}
                  src={reader.avatar}
                />
              ))}
            </div>
          </div>
          {article.authorized && (
            <Row gutter={16} className='text-center'>
              <Col xs={12} sm={6}>
                <Statistic
                  title={`${t('article.price')}(${article.currency.symbol})`}
                  value={article.price}
                />
              </Col>
              <Col xs={12} sm={6}>
                <Statistic
                  title={t('article.orders_count')}
                  value={article.ordersCount}
                />
              </Col>
              <Col xs={12} sm={6}>
                <Statistic
                  title={`${t('article.revenue')}(USD)`}
                  value={
                    article.revenueUsd ? article.revenueUsd.toFixed(4) : 0.0
                  }
                />
              </Col>
              <Col xs={12} sm={6}>
                <Statistic
                  title={t('article.my_share')}
                  value={
                    article.myShare ? (article.myShare * 100).toFixed(3) : '0.0'
                  }
                />
              </Col>
            </Row>
          )}
        </div>
      )}
      <Divider />
      <CommentsComponent
        commentableType='Article'
        commentableId={article.id}
        authorized={article.authorized}
        commentingSubscribed={article.commentingSubscribed}
        articleUuid={article.uuid}
      />
      <div className='mt-8 mb-16'>
        {i18n.language.includes('CN') && (
          <div className='mb-6'>
            <Card>
              <Card.Meta
                avatar={
                  <img
                    className='w-8 h-8 rounded-full'
                    src={CHINESE_MIXIN_GROUP_AVATAR_URL}
                  />
                }
                title={
                  <Row style={{ alignItems: 'center' }}>
                    <Col style={{ flex: 1, marginRight: 10 }}>
                      PRSDigg 中文社区
                    </Col>
                    <Col>
                      <Button
                        type='primary'
                        shape='round'
                        size='small'
                        target={mixinEnv ? '' : '_blank'}
                        href={
                          mixinEnv
                            ? `mixin://users/${CHINESE_MIXIN_GROUP_APP_ID}`
                            : `https://mixin-www.zeromesh.net/codes/${CHINESE_MIXIN_GROUP_CODE_ID}`
                        }
                      >
                        加入
                      </Button>
                    </Col>
                  </Row>
                }
                description={CHINESE_MIXIN_GROUP_DESCRIPTION}
              />
            </Card>
          </div>
        )}
      </div>
    </div>
  );
}
