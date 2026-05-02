export function generate(input: any) {
  // Gerar valores aleatórios
  const secretkey = Math.random().toString(36).substring(2, 34);
  const randomPasswordRedis = Math.random().toString(36).substring(2, 15);
  const randomPasswordPostgres = Math.random().toString(36).substring(2, 15);

  // 🎯 Variáveis de ambiente compartilhadas
  const env = [
    `SECRET_KEY_BASE=${secretkey}`,
    `DEFAULT_LOCALE=${input.defaultLocale || "pt-br"}`,
    `FORCE_SSL=false`,
    `ENABLE_ACCOUNT_SIGNUP=true`,
    `REDIS_URL=redis://default@$(PROJECT_NAME)_${input.redisServiceName}:6379`,
    `REDIS_PASSWORD=${randomPasswordRedis}`,
    `REDIS_OPENSSL_VERIFY_MODE=none`,
    `POSTGRES_DATABASE=$(PROJECT_NAME)`,
    `POSTGRES_HOST=$(PROJECT_NAME)_${input.databaseServiceName}`,
    `POSTGRES_USERNAME=postgres`,
    `POSTGRES_PASSWORD=${randomPasswordPostgres}`,
    `RAILS_MAX_THREADS=5`,
    `NODE_ENV=production`,
    `RAILS_ENV=production`,
    `INSTALLATION_ENV=docker`,
    `TRUSTED_PROXIES=*`,
    `FEATURE_CRM_ENABLED=true`,
  ].join("\n");

  const services = [
    {
      type: "app",
      data: {
        serviceName: input.appServiceName || "chatwoot-crm",
        env: [
          `FRONTEND_URL=https://$(PRIMARY_DOMAIN)`,
          ...env.split("\n"),
        ].join("\n"),
        source: {
          type: "image",
          image: input.appServiceImage || "seu-dockerhub-user/chatwoot-crm:latest",
        },
        domains: [
          {
            host: "$(EASYPANEL_DOMAIN)",
            port: 3000,
          },
        ],
        deploy: {
          command: "bundle exec rails db:chatwoot_prepare && bundle exec rails s -p 3000 -b 0.0.0.0",
        },
        mounts: [
          {
            type: "volume",
            name: "data",
            mountPath: "/data/storage",
          },
          {
            type: "volume",
            name: "app",
            mountPath: "/app/storage",
          },
        ],
      },
    },
    {
      type: "app",
      data: {
        serviceName: input.sidekiqServiceName || "chatwoot-sidekiq",
        env: [
          `FRONTEND_URL=https://$(PROJECT_NAME)-${input.appServiceName}.$(EASYPANEL_HOST)`,
          ...env.split("\n"),
        ].join("\n"),
        source: {
          type: "image",
          image: input.appServiceImage || "seu-dockerhub-user/chatwoot-crm:latest",
        },
        deploy: {
          command: "bundle exec sidekiq -C config/sidekiq.yml",
        },
        mounts: [
          {
            type: "bind",
            hostPath: `/etc/easypanel/projects/$(PROJECT_NAME)/${input.appServiceName}/volumes/app`,
            mountPath: "/app/storage",
          },
        ],
      },
    },
    {
      type: "redis",
      data: {
        serviceName: input.redisServiceName || "chatwoot-redis",
        password: randomPasswordRedis,
      },
    },
    {
      type: "postgres",
      data: {
        serviceName: input.databaseServiceName || "chatwoot-db",
        image: "pgvector/pgvector:pg17",
        password: randomPasswordPostgres,
      },
    },
  ];

  return { services };
}
