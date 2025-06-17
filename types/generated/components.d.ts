import type { Schema, Struct } from '@strapi/strapi';

export interface TranslationsArticleTranslations
  extends Struct.ComponentSchema {
  collectionName: 'components_translations_article_translations';
  info: {
    description: '';
    displayName: 'Article Translations';
  };
  options: {
    draftAndPublish: false;
  };
  attributes: {
    content: Schema.Attribute.RichText;
    excerpt: Schema.Attribute.Text;
    language: Schema.Attribute.Enumeration<['en', 'fr']> &
      Schema.Attribute.Required;
    title: Schema.Attribute.String & Schema.Attribute.Required;
  };
}

declare module '@strapi/strapi' {
  export module Public {
    export interface ComponentSchemas {
      'translations.article-translations': TranslationsArticleTranslations;
    }
  }
}
