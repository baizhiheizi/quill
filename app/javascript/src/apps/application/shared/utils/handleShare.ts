import { Article } from '@graphql';
import { message } from 'antd';
import copy from 'copy-to-clipboard';
import { encode as encode64 } from 'js-base64';
import { PRSDIGG_ICON_URL } from '../constants';

export const handleShare = (
  article: Partial<Article>,
  mixinEnv: boolean,
  appId: string,
) => {
  const articleUrl = `${location.origin}/articles/${article.uuid}`;
  if (mixinEnv) {
    const data = {
      action: articleUrl,
      app_id: appId,
      description: `来自 ${article.author.name} 的好文`,
      icon_url: PRSDIGG_ICON_URL,
      title: article.title.slice(0, 36),
    };
    location.replace(
      `mixin://send?category=app_card&data=${encodeURIComponent(
        encode64(JSON.stringify(data)),
      )}`,
    );
  } else {
    copy(articleUrl);
    message.success('成功复制链接');
  }
};
