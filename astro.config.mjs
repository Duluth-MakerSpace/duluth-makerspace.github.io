import { defineConfig } from 'astro/config';
import NetlifyCMS from 'astro-netlify-cms';
import sitemap from '@astrojs/sitemap';
import mdx from '@astrojs/mdx';
import image from '@astrojs/image';
import lit from '@astrojs/lit';

// https://astro.build/config
export default defineConfig({
    site: 'https://duluth-makerspace.github.io',
    sitemap: true,
    // Generate sitemap (set to "false" to disable)
    integrations: [
        lit(),
        sitemap(), 
        mdx(),
        image(), 
        NetlifyCMS({
            config: {
                backend: {
                    name: 'git-gateway',
                    branch: 'main',
                    repo: 'Duluth-Makerspace/duluth-makerspace.github.io'
                },
                site_url: 'https://duluth-makerspace.github.io',
                publish_mode: 'editorial_workflow',
                media_folder: 'public/assets/uploads',
                public_folder: '/assets/uploads',
                collections: [
                    {
                        name: 'posts',
                        label: 'Blog Posts',
                        label_singular: 'Blog Post',
                        folder: 'src/pages/blog/posts',
                        description: 'Blog posts visible on the website',
                        slug: '{{year}}-{{month}}-{{day}}-{{slug}}',
                        summary: '{{title}} -- {{year}}/{{month}}/{{day}}',
                        view_filters: [
                            {
                                label: 'Posts With Index',
                                field: 'title',
                                pattern: 'This is post #',
                            },
                            {
                                label: 'Posts Without Index',
                                field: 'title',
                                pattern: 'front matter post'
                            },
                            {
                                label: 'Drafts',
                                field: 'draft',
                                pattern: true
                            }
                        ],
                        view_groups: [
                            {
                                label: 'Year',
                                field: 'date',
                                pattern: '\d{4}',
                            },
                            {
                                label: 'Drafts',
                                field: 'draft',
                            }
                        ],
                        // summary: "{{title | upper}} - {{publishDate | date('YYYY-MM-DD')}} – {{body | truncate(20, '***')}}",
                        create: true,
                        delete: true,
                        
                        fields: [
                            { label: 'Title', name: 'title', widget: 'string', tagname: 'h1' },
                            { label: 'Draft', name: 'draft', widget: 'boolean', default: false },
                            {
                                label: 'Publish Date',
                                name: 'date',
                                widget: 'datetime',
                                date_format: 'YYYY-MM-DD',
                                time_format: 'HH:mm',
                                format: 'YYYY-MM-DD HH:mm',
                            },
                            {
                                label: 'Cover Image',
                                name: 'image',
                                widget: 'image',
                                required: false,
                                tagname: ''
                            },
                            { label: 'Description', name: 'description', widget: 'string', tagname: 'h4', required: false },
                            
                            { label: 'Body', name: 'body', widget: 'markdown', hint: 'Main content goes here.' },
                            { label: 'Layout', name: 'layout', widget: 'hidden', default: '../../../layouts/Post.astro'}
                        ],
                      },
                ],
            },
            previewStyles: [
                // Path to a local CSS file, relative to your project’s root directory
                'src/styles/reset.css',
                'src/styles/theme.css',
                'src/styles/typography.css',
                'src/styles/global.css',
            ]
        }),
    ], // Add renderers to the config
    // This is for the astro-icon package. You can find more about the package here: https://www.npmjs.com/package/astro-icon
    vite: {
        ssr: {
            external: ['svgo'],
        },
    },
});
