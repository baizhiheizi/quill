import { updateActiveMenu } from '@dashboard/shared';
import { useCreateArticleMutation } from '@graphql';
import Editor, { commands } from '@uiw/react-md-editor';
import {
  Button,
  Form,
  Input,
  InputNumber,
  message,
  Modal,
  PageHeader,
  Radio,
} from 'antd';
import React from 'react';
import { useTranslation } from 'react-i18next';
import { Link, useHistory } from 'react-router-dom';

export default function ArticleNewPage() {
  updateActiveMenu('articles');
  const history = useHistory();
  const { t } = useTranslation();
  const [createArticle, { loading }] = useCreateArticleMutation({
    update(
      _,
      {
        data: {
          createArticle: { error },
        },
      },
    ) {
      if (error) {
        message.error(error);
      } else {
        message.success(t('messages.successSubmitted'));
        history.replace('/articles');
      }
    },
  });
  return (
    <div>
      <PageHeader
        title={t('dashboard.pages.articleNew')}
        breadcrumb={{
          routes: [
            { path: '/articles', breadcrumbName: t('dashboard.menu.articles') },
            { path: '', breadcrumbName: t('dashboard.pages.articleNew') },
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
        initialValues={{ state: 'published' }}
        labelCol={{ span: 2 }}
        wrapperCol={{ span: 22 }}
        onFinish={(values) => {
          const { title, content, price, intro } = values;
          if (!title || !content || !price || !intro) {
            message.warn(t('article.form.warning'));
          } else {
            Modal.confirm({
              title: t('article.form.createConfirm'),
              centered: true,
              okText: t('article.form.createOkText'),
              cancelText: t('article.form.createCancelText'),
              onOk: () => createArticle({ variables: { input: values } }),
            });
          }
        }}
      >
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
        <Form.Item label={t('article.stateText')} name='state'>
          <Radio.Group
            options={[
              { label: t('article.state.published'), value: 'published' },
              { label: t('article.state.hidden'), value: 'hidden' },
            ]}
          />
        </Form.Item>
        <Form.Item wrapperCol={{ xs: { offset: 0 }, sm: { offset: 2 } }}>
          <Button
            size='large'
            type='primary'
            htmlType='submit'
            loading={loading}
          >
            {t('article.form.createBtn')}
          </Button>
        </Form.Item>
      </Form>
    </div>
  );
}
