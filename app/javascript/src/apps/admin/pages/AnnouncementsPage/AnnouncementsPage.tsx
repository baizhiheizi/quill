import LoadingComponent from '@admin/components/LoadingComponent/LoadingComponent';
import {
  Announcement,
  useAdminAnnouncementConnectionQuery,
  useAdminCreateAnouncementMutation,
  useAdminDeleteAnouncementMutation,
  useAdminDeliverAnouncementMutation,
  useAdminPreviewAnouncementMutation,
  useAdminUpdateAnouncementMutation,
} from '@graphql';
import {
  Button,
  Divider,
  Input,
  message,
  Modal,
  PageHeader,
  Popconfirm,
  Radio,
  Table,
} from 'antd';
import { ColumnProps } from 'antd/es/table';
import React, { useState } from 'react';

export default function AnnouncementsPage() {
  const {
    data,
    loading,
    fetchMore,
    refetch,
  } = useAdminAnnouncementConnectionQuery();
  const [content, setContent] = useState('');
  const [messageType, setMessageType] = useState<
    'PLAIN_TEXT' | 'PLAIN_POST' | string
  >('PLAIN_TEXT');
  const [editing, setEditing] = useState(null);
  const [modalVisible, setModalVisible] = useState(false);
  const [createAnnouncement] = useAdminCreateAnouncementMutation({
    update(
      _,
      {
        data: {
          adminCreateAnnouncement: { error },
        },
      },
    ) {
      if (error) {
        message.error(error);
      } else {
        setModalVisible(false);
        message.success('Created!');
        refetch();
      }
    },
  });
  const [updateAnnouncement] = useAdminUpdateAnouncementMutation({
    update(
      _,
      {
        data: {
          adminUpdateAnnouncement: { error },
        },
      },
    ) {
      if (error) {
        message.error(error);
      } else {
        setModalVisible(false);
        message.success('updated!');
        refetch();
      }
    },
  });
  const [deleteAnnouncement] = useAdminDeleteAnouncementMutation({
    update(
      _,
      {
        data: {
          adminDeleteAnnouncement: { error },
        },
      },
    ) {
      if (error) {
        message.error(error);
      } else {
        message.success('deleted!');
        refetch();
      }
    },
  });
  const [deliverAnnouncement] = useAdminDeliverAnouncementMutation({
    update(
      _,
      {
        data: {
          adminDeliverAnnouncement: { error },
        },
      },
    ) {
      if (error) {
        message.error(error);
      } else {
        message.success('delivered!');
        refetch();
      }
    },
  });
  const [previewAnnouncement] = useAdminPreviewAnouncementMutation({
    update(
      _,
      {
        data: {
          adminPreviewAnnouncement: { error },
        },
      },
    ) {
      if (error) {
        message.error(error);
      } else {
        message.success('Check it in admin group!');
        refetch();
      }
    },
  });

  if (loading) {
    return <LoadingComponent />;
  }
  const {
    adminAnnouncementConnection: {
      nodes: announcements,
      pageInfo: { hasNextPage, endCursor },
    },
  } = data;

  const columns: Array<ColumnProps<Announcement>> = [
    {
      dataIndex: 'id',
      key: 'id',
      title: 'ID',
    },
    {
      dataIndex: 'messageType',
      key: 'messageType',
      title: 'messageType',
    },
    {
      dataIndex: 'content',
      key: 'content',
      render: (content) => <div>{content}</div>,
      title: 'content',
    },
    {
      dataIndex: 'state',
      key: 'state',
      title: 'state',
    },
    {
      dataIndex: 'deliveredAt',
      key: 'deliveredAt',
      render: (deliveredAt) => deliveredAt || '-',
      title: 'deliveredAt',
    },
    {
      dataIndex: 'actions',
      key: 'actions',
      render: (_, announcement) => (
        <span>
          <Popconfirm
            title='Are you sure to deliver message to all users?'
            onConfirm={() =>
              deliverAnnouncement({
                variables: { input: { id: announcement.id } },
              })
            }
          >
            <a>Deliver</a>
          </Popconfirm>
          <Divider type='vertical' />
          <Popconfirm
            title='Are you sure to deliver message to admin group for preview?'
            onConfirm={() =>
              previewAnnouncement({
                variables: { input: { id: announcement.id } },
              })
            }
          >
            <a>Preview</a>
          </Popconfirm>
          <Divider type='vertical' />
          <Popconfirm
            title='Are you sure to delete?'
            onConfirm={() =>
              deleteAnnouncement({
                variables: { input: { id: announcement.id } },
              })
            }
          >
            <a>Delete</a>
          </Popconfirm>
          <Divider type='vertical' />
          <a
            onClick={() => {
              setEditing(announcement);
              setContent(announcement.content);
              setMessageType(announcement.messageType);
              setModalVisible(true);
            }}
          >
            Edit
          </a>
        </span>
      ),
      title: 'Actions',
    },
  ];

  return (
    <div>
      <PageHeader title='Announcements' />
      <div style={{ marginBottom: '1rem' }}>
        <Button
          type='primary'
          onClick={() => {
            setContent('');
            setMessageType('PLAIN_TEXT');
            setEditing(null);
            setModalVisible(true);
          }}
        >
          New
        </Button>
        <Modal
          title={editing ? 'Edit' : 'New'}
          closable={false}
          visible={modalVisible}
          onCancel={() => setModalVisible(false)}
          onOk={() => {
            if (editing) {
              updateAnnouncement({
                variables: {
                  input: {
                    id: editing.id,
                    content,
                    messageType,
                  },
                },
              });
            } else {
              createAnnouncement({
                variables: {
                  input: {
                    content,
                    messageType,
                  },
                },
              });
            }
          }}
        >
          <div>
            <Input.TextArea
              value={content}
              onChange={(e) => setContent(e.currentTarget.value)}
              autoSize={{ minRows: 3, maxRows: 10 }}
            />
          </div>
          <div>
            <Radio.Group
              value={messageType}
              onChange={(e) => setMessageType(e.target.value)}
            >
              <Radio value='PLAIN_TEXT'>Text</Radio>
              <Radio value='PLAIN_POST'>Post</Radio>
            </Radio.Group>
          </div>
        </Modal>
      </div>
      <Table
        scroll={{ x: true }}
        columns={columns}
        dataSource={announcements}
        rowKey='id'
        pagination={false}
      />
      <div style={{ margin: '1rem', textAlign: 'center' }}>
        <Button
          type='link'
          loading={loading}
          disabled={!hasNextPage}
          onClick={() => {
            fetchMore({
              variables: {
                after: endCursor,
              },
            });
          }}
        >
          {hasNextPage ? 'Load More' : 'No More'}
        </Button>
      </div>
    </div>
  );
}
