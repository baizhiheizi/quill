import LoadingComponent from '@dashboard/components/LoadingComponent/LoadingComponent';
import { useMyArticleQuery, useUpdateArticleMutation } from '@graphql';
import Editor, { commands } from '@uiw/react-md-editor';
import {
  Avatar,
  Button,
  Form,
  Input,
  InputNumber,
  message,
  Modal,
  PageHeader,
  Select,
  Space,
} from 'antd';
import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Link, useHistory, useParams } from 'react-router-dom';
import EditableTagsComponent from '../../components/EditableTagsComponent/EditableTagsComponent';

export default function ArticleEditPage() {
  const { uuid } = useParams<{ uuid: string }>();
  const [editedPrice, setEditedPrice] = useState(0);
  const history = useHistory();
  const { t } = useTranslation();
  const [tags, setTags] = useState<string[]>([]);
  const { data, loading } = useMyArticleQuery({
    fetchPolicy: 'network-only',
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

  useEffect(() => {
    setTags(data?.myArticle?.tagNames || []);
  }, [data]);

  if (loading) {
    return <LoadingComponent />;
  }

  const { myArticle } = data;

  return (
    <div>
      <PageHeader
        title={t('dashboard.pages.articleEdit')}
        breadcrumb={{
          routes: [
            { path: '/articles', breadcrumbName: t('dashboard.menu.articles') },
            { path: `/articles/${uuid}`, breadcrumbName: myArticle.title },
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
          title: myArticle.title,
          intro: myArticle.intro,
          content: myArticle.content,
          price: myArticle.price,
          assetId: myArticle.assetId,
        }}
        labelCol={{ span: 2 }}
        wrapperCol={{ span: 22 }}
        onFinish={(values) => {
          const { uuid, title, content, price, intro } = values;
          if (!title || !content || !price || !intro) {
            message.warn(t('article.form.warning'));
          } else {
            Modal.confirm({
              title: t('article.form.updateConfirm'),
              centered: true,
              okText: t('article.form.updateOkText'),
              cancelText: t('article.form.updateCancelText'),
              onOk: () =>
                updateArticle({
                  variables: {
                    input: {
                      uuid,
                      title,
                      content,
                      price,
                      intro,
                      tagNames: tags,
                    },
                  },
                }),
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
        <Form.Item label={t('article.tags')}>
          <EditableTagsComponent tags={tags} setTags={setTags} />
        </Form.Item>
        <Form.Item
          label={t('article.price')}
          extra={`≈ $${(
            myArticle.currency.priceUsd * (editedPrice || myArticle.price)
          ).toFixed(4)}`}
        >
          <Space>
            <Form.Item
              name='price'
              noStyle
              rules={[
                { required: true },
                {
                  validator: (_, value) => {
                    if (
                      myArticle.currency.symbol === 'BTC' &&
                      value >= 0.000_001
                    ) {
                      return Promise.resolve();
                    } else if (
                      myArticle.currency.symbol === 'PRS' &&
                      value >= 1
                    ) {
                      return Promise.resolve();
                    } else {
                      return Promise.reject(t('article.form.priceIsTooLow'));
                    }
                  },
                },
              ]}
            >
              <InputNumber
                onChange={(value) =>
                  setEditedPrice(parseFloat(value.toString()))
                }
                style={{ minWidth: 130 }}
                min={0.000_001}
                step='0.000001'
                precision={6}
                placeholder='0.0'
              />
            </Form.Item>
            <Form.Item name='assetId' noStyle rules={[{ required: true }]}>
              <Select disabled>
                <Select.Option
                  key={myArticle.currency.assetId}
                  value={myArticle.currency.assetId}
                >
                  <Space>
                    <Avatar size='small' src={myArticle.currency.iconUrl} />
                    {myArticle.currency.symbol}
                  </Space>
                </Select.Option>
              </Select>
            </Form.Item>
          </Space>
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
