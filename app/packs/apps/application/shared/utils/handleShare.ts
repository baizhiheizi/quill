import { message } from 'antd';
import { imagePath } from 'apps/shared';
import copy from 'copy-to-clipboard';
import { Article, Tag } from 'graphqlTypes';
import { encode as encode64 } from 'js-base64';

export const handleArticleShare = (
  article: Partial<Article>,
  mixinEnv: boolean,
  appId: string,
  logoFile?: string,
) => {
  const articleUrl = `${location.origin}/articles/${article.uuid}`;
  const data = {
    action: articleUrl,
    app_id: appId,
    description: `${article.author.name}`,
    icon_url: `${location.origin}${imagePath(logoFile || 'logo.png')}`,
    title: article.title.slice(0, 36),
  };
  handleShare(articleUrl, data, mixinEnv);
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
    icon_url: `${location.origin}${imagePath(logoFile || 'logo.png')}`,
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
