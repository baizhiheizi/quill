import i18n from 'i18next';
import LanguageDetector from 'i18next-browser-languagedetector';
import { initReactI18next } from 'react-i18next';
import translations from './translations.json';

export const i18nCall = (availableLocales: string[]) => {
  i18n
    // detect user language
    // learn more: https://github.com/i18next/i18next-browser-languageDetector
    .use(LanguageDetector)
    // pass the i18n instance to react-i18next.
    .use(initReactI18next)
    // init i18next
    // for all options read: https://www.i18next.com/overview/configuration-options
    .init({
      debug: true,
      fallbackLng: availableLocales || ['en'],
      interpolation: {
        escapeValue: false, // not needed for react as it escapes by default
      },
      load: 'currentOnly',
      keySeparator: false,
      resources: {
        en: { translation: translations['en'] },
        'zh-CN': { translation: translations['zh-CN'] },
        ja: { translation: translations['ja'] },
      },
      supportedLngs: availableLocales || ['en', 'zh-CN', 'ja'],
    });
};
