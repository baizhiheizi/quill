import { PlusOutlined } from '@ant-design/icons';
import { Input, Tag, Tooltip } from 'antd';
import React, { useEffect, useRef, useState } from 'react';

export default function EditableTagsComponent(props: {
  tags: string[];
  setTags: (tags: string[]) => any;
}) {
  const { tags, setTags } = props;
  const [inputVisible, setInputVisible] = useState(false);
  const [inputValue, setInputValue] = useState('');
  const [editInputIndex, setEditInputIndex] = useState(-1);
  const [editInputValue, setEditInputValue] = useState('');
  const inputRef = useRef(null);
  const editInputRef = useRef(null);

  useEffect(() => {
    if (inputVisible) {
      inputRef.current.focus();
    }
  }, [inputVisible]);

  useEffect(() => {
    if (editInputIndex !== -1) {
      editInputRef.current.focus();
    }
  }, [editInputIndex]);

  const handleRemove = (removedTag: string) =>
    setTags(tags.filter((tag) => tag !== removedTag));

  const handleInputConfirm = () => {
    if (inputValue && tags.indexOf(inputValue) === -1) {
      setTags([...tags, inputValue]);
    }
    setInputValue('');
    setInputVisible(false);
  };

  const handleEditInputConfirm = () => {
    const newTags = [...tags];
    newTags[editInputIndex] = editInputValue;
    setTags(newTags);
    setEditInputValue('');
    setEditInputIndex(-1);
  };

  return (
    <div>
      {tags.map((tag, index) => {
        if (editInputIndex === index) {
          return (
            <Input
              ref={editInputRef}
              style={{ width: 78, marginRight: 8, verticalAlign: 'top' }}
              size='small'
              key={tag}
              value={editInputValue}
              onChange={(e) => setEditInputValue(e.target.value)}
              onBlur={handleEditInputConfirm}
              onPressEnter={handleEditInputConfirm}
            />
          );
        }

        const isLongTag = tag.length > 20;

        const tagElem = (
          <Tag key={tag} closable onClose={() => handleRemove(tag)}>
            <span
              onDoubleClick={(e) => {
                if (index !== 0) {
                  setEditInputIndex(index);
                  setEditInputValue(tag);
                  editInputRef.current.focus();
                  e.preventDefault();
                }
              }}
            >
              #{isLongTag ? `${tag.slice(0, 20)}...` : tag}
            </span>
          </Tag>
        );

        return isLongTag ? (
          <Tooltip title={tag} key={tag}>
            {tagElem}
          </Tooltip>
        ) : (
          tagElem
        );
      })}
      {inputVisible && (
        <Input
          ref={inputRef}
          style={{ width: 78, marginRight: 8, verticalAlign: 'top' }}
          size='small'
          type='text'
          value={inputValue}
          onChange={(e) => setInputValue(e.target.value)}
          onBlur={handleInputConfirm}
          onPressEnter={handleInputConfirm}
        />
      )}
      {!inputVisible && (
        <Tag
          style={{
            background: '#fff',
            borderStyle: 'dashed',
          }}
          onClick={() => setInputVisible(true)}
        >
          <PlusOutlined /> New Tag
        </Tag>
      )}
    </div>
  );
}
