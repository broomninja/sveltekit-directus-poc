module.exports = {
  server: {
    type: "meilisearch",
    host: "http://search:7700",
    key: `${process.env.MEILI_ADMIN_API_KEY}`,
  },
  reindexOnStart: true,
  batchLimit: 100,
  collections: {
    ddb_company: {
      filter: {
        status: {
          _eq: "active",
        },
      },
      indexName: "index_company",
      fields: ["id", "name", "slug"],
    },
    ddb_feedback: {
      filter: {
        status: {
          _eq: "public",
        },
      },
      indexName: "index_feedback",
      fields: [
        "id",
        "title",
        "content",
        "author_id.first_name",
        "author_id.last_name",
        "company_id.name",
        "company_id.slug",
        "date_created",
      ],
      transform: (item, { flattenObject, striptags }) => {
        return {
          ...flattenObject(item),
          content: striptags(item.content),
        };
      },
      settings: {
        searchableAttributes: [
          "title",
          "content",
          "author_id.first_name",
          "company_id.slug",
        ],
      },
    },
  },
};
