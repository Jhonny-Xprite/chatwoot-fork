# Deploy no EasyPanel com Dockerfile

Use esta abordagem apenas se voce for subir um unico container da aplicacao.

Para um deploy completo do Chatwoot com `chatwoot` + `sidekiq` + `postgres` + `redis`, prefira `docker-compose.easypanel.yml`.

## Quando usar Dockerfile

- Quando o banco e o Redis ja existem fora desta aplicacao
- Quando o worker `sidekiq` sera criado como outro servico separado
- Quando voce quer somente gerar a imagem da aplicacao

## Campos no EasyPanel

Repository URL:
```text
https://github.com/Jhonny-Xprite/chatwoot-fork
```

Branch:
```text
feat/crm-advanced-filters-automation
```

Dockerfile path:
```text
./Dockerfile
```

Build context:
```text
./
```

## Importante

Se o objetivo for subir tudo de uma vez no EasyPanel, nao use a opcao "Dockerfile" para este projeto.

Nesse caso, use a opcao "Docker Compose" e cole o conteudo de `docker-compose.easypanel.yml`.
