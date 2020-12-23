import {
  ArticleQueryHookResult,
  useArticleQuery,
  useUpdateArticleMutation,
} from '@graphql';
import Editor, { commands } from '@uiw/react-md-editor';
import {
  Button,
  Form,
  Input,
  InputNumber,
  message,
  Modal,
  PageHeader,
} from 'antd';
import React from 'react';
import { useTranslation } from 'react-i18next';
import { Link, useHistory, useParams } from 'react-router-dom';
import LoadingComponent from '@dashboard/components/LoadingComponent/LoadingComponent';
import { updateActiveMenu } from '@dashboard/shared';

export default function ArticleEditPage() {
  updateActiveMenu('articles');
  const { uuid } = useParams<{ uuid: string }>();
  const history = useHistory();
  const { t } = useTranslation();
  const { data, loading }: ArticleQueryHookResult = useArticleQuery({
    variables: { uuid },
  });
  const [updateArticle, { loading: updating }] = useUpdateArticleMutation({
    update(
      _,
      {
        data: {
          updateArticle: { error: err },
        },
      },
    ) {
      if (err) {
        message.error(err);
      } else {
        message.success(t('messages.successSubmitted'));
        history.replace(`/articles/${uuid}`);
      }
    },
  });

  if (loading) {
    return <LoadingComponent />;
  }

  const { article } = data;

  return (
    <div>
      <PageHeader
        title={t('dashboard.pages.articleEdit')}
        breadcrumb={{
          routes: [
            { path: '/articles', breadcrumbName: t('dashboard.menu.articles') },
            { path: `/articles/${uuid}`, breadcrumbName: article.title },
            { path: '', breadcrumbName: t('dashboard.pages.articleEdit') },
          ],
          itemRender: (route, _params, routes, _paths) => {
            const last = routes.indexOf(route) === routes.length - 1;
            return last ? (
              <span>{route.breadcrumbName}</span>
            ) : (
              <Link to={route.path}>{route.breadcrumbName}</Link>
            );
          },
        }}
      />
      <Form
        initialValues={{
          uuid,
          title: article.title,
          intro: article.intro,
          content: article.content,
          price: article.price,
        }}
        labelCol={{ span: 2 }}
        wrapperCol={{ span: 22 }}
        onFinish={(values) => {
          const { title, content, price, intro } = values;
          if (!title || !content || !price || !intro) {
            message.warn(t('article.form.warning'));
          } else {
            Modal.confirm({
              title: t('article.form.updateConfirm'),
              centered: true,
              okText: t('article.form.updateOkText'),
              cancelText: t('article.form.updateCancelText'),
              onOk: () => updateArticle({ variables: { input: values } }),
            });
          }
        }}
      >
        <Form.Item style={{ display: 'none' }} name='uuid'>
          <Input />
        </Form.Item>
        <Form.Item label={t('article.title')} name='title'>
          <Input placeholder={t('article.form.titlePlaceHolder')} />
        </Form.Item>
        <Form.Item label={t('article.content')} name='content'>
          <Editor
            textareaProps={{
              placeholder: t('article.form.contentPlaceHolder'),
            }}
            autoFocus={false}
            preview='edit'
            height={500}
            commands={[
              commands.bold,
              commands.italic,
              commands.quote,
              commands.hr,
              commands.title,
              commands.divider,
              commands.link,
              commands.code,
              commands.divider,
              commands.image,
              commands.codeEdit,
              commands.codePreview,
            ]}
          />
        </Form.Item>
        <Form.Item label={t('article.intro')} name='intro'>
          <Input.TextArea placeholder={t('article.form.introPlaceHolder')} />
        </Form.Item>
        <Form.Item label={t('article.price')} name='price'>
          <InputNumber min={1} precision={4} placeholder='0.0' />
        </Form.Item>
        <Form.Item wrapperCol={{ xs: { offset: 0 }, sm: { offset: 2 } }}>
          <Button
            size='large'
            type='primary'
            htmlType='submit'
            loading={updating}
          >
            {t('article.form.updateBtn')}
          </Button>
        </Form.Item>
      </Form>
    </div>
  );
}
