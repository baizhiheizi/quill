import { Article, Tag } from '@graphql';
import { message } from 'antd';
import copy from 'copy-to-clipboard';
import { encode as encode64 } from 'js-base64';
import { PRSDIGG_ICON_URL } from '../constants';

export const handleArticleShare = (
  article: Partial<Article>,
  mixinEnv: boolean,
  appId: string,
) => {
  const articleUrl = `${location.origin}/articles/${article.uuid}`;
  const data = {
    action: articleUrl,
    app_id: appId,
    description: `来自 ${article.author.name} 的好文`,
    icon_url: PRSDIGG_ICON_URL,
    title: article.title.slice(0, 36),
  };
  handleShare(articleUrl, data, mixinEnv);
};

export const handleTagShare = (
  tag: Partial<Tag>,
  mixinEnv: boolean,
  appId: string,
) => {
  const tagUrl = `${location.origin}/tags/${tag.id}`;
  const data = {
    action: tagUrl,
    app_id: appId,
    description: `共有 ${tag.articlesCount} 篇好文`,
    icon_url: PRSDIGG_ICON_URL,
    title: `#${tag.name} 话题文章`,
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
