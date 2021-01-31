import React from 'react';
import MDEditor from '@uiw/react-md-editor';
import { useTranslation } from 'react-i18next';

export default function RulesPage() {
  const { t } = useTranslation();
  return (
    <div style={{ marginTop: 20 }}>
      <MDEditor.Markdown source={t('rulesPage.content')} />
    </div>
  );
}
