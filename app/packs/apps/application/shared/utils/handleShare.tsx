import { ShareAltOutlined, CopyOutlined } from '@ant-design/icons';
import { Dropdown, Menu, message } from 'antd';
import { imagePath, usePrsdigg, useUserAgent } from 'apps/shared';
import copy from 'copy-to-clipboard';
import { Article, Tag } from 'graphqlTypes';
import { encode as encode64 } from 'js-base64';
import React, { ReactChild, ReactChildren } from 'react';
import { useTranslation } from 'react-i18next';
import {
  FacebookIcon,
  FacebookShareButton,
  TwitterIcon,
  TwitterShareButton,
} from 'react-share';

export const handleArticleShare = (
  article: Partial<Article>,
  appId: string,
  logoFile?: string,
) => {
  const articleUrl = `${location.origin}/articles/${article.uuid}`;
  const data = {
    action: articleUrl,
    app_id: appId,
    description: `${article.author.name}`,
    icon_url: `${imagePath(logoFile || 'logo.png')}`,
    title: article.title.slice(0, 36),
  };
  location.replace(
    `mixin://send?category=app_card&data=${encodeURIComponent(
      encode64(JSON.stringify(data)),
    )}`,
  );
};

export const handleTagShare = (
  tag: Partial<Tag>,
  mixinEnv: boolean,
  appId: string,
  logoFile?: string,
) => {
  const tagUrl = `${location.origin}/tags/${tag.id}`;
  const data = {
    action: tagUrl,
    app_id: appId,
    description: `x ${tag.articlesCount}`,
    icon_url: `${imagePath(logoFile || 'logo.png')}`,
    title: `#${tag.name}`,
  };
  handleShare(tagUrl, data, mixinEnv);
};

export const handleShare = (
  url: string,
  appCardData: object,
  mixinEnv: boolean,
) => {
  if (mixinEnv) {
    location.replace(
      `mixin://send?category=app_card&data=${encodeURIComponent(
        encode64(JSON.stringify(appCardData)),
      )}`,
    );
  } else {
    copy(url);
    message.success('Copied');
  }
};

export function ArticleShareButton(props: {
  article: Partial<Article>;
  children: ReactChild | ReactChildren;
}) {
  const { mixinEnv } = useUserAgent();
  const { t } = useTranslation();
  const { logoFile, twitterAccount, appName, appId } = usePrsdigg();
  const { article, children } = props;
  const shareUrl = `${location.origin}/articles/${article.uuid}`;
  return (
    <Dropdown
      trigger={['click', 'hover']}
      overlay={
        <Menu>
          {mixinEnv && (
            <Menu.Item
              key='mixin'
              onClick={() => {
                handleArticleShare(article, appId, logoFile);
              }}
            >
              <div className='flex items-center space-x-2'>
                <ShareAltOutlined />
                <span>{t('mixin_contact')}</span>
              </div>
            </Menu.Item>
          )}
          <Menu.Item key='twittier'>
            <TwitterShareButton
              url={shareUrl}
              title={article.title}
              hashtags={article.tagNames}
              via={twitterAccount}
            >
              <div className='flex items-center space-x-2'>
                <TwitterIcon size={16} round={true} />
                <span>Twitter</span>
              </div>
            </TwitterShareButton>
          </Menu.Item>
          <Menu.Item key='facebook'>
            <FacebookShareButton
              url={shareUrl}
              quote={article.title}
              hashtag={appName}
            >
              <div className='flex items-center space-x-2'>
                <FacebookIcon size={16} round={true} />
                <span>Facebook</span>
              </div>
            </FacebookShareButton>
          </Menu.Item>
          <Menu.Item
            key='url'
            onClick={() => {
              copy(shareUrl);
              message.success(t('copied'));
            }}
          >
            <div className='flex items-center space-x-2'>
              <CopyOutlined />
              <span>{t('copy_url')}</span>
            </div>
          </Menu.Item>
        </Menu>
      }
    >
      {children}
    </Dropdown>
  );
}
