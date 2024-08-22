# Power Path Finder

- [ONBOARDING](./ONBOARDING.md)

## Services

Power Path Finder is a platform based on microservices. Each service is a separate project with its own repository. The services are:

**Routes**
- repo: [ppf-route-api](./ppf-route-api/README.md)
- port: 8080
- auth: `Authorization: Token <token>`

**Users**
- repo: [ppf-user-api](./ppf-user-api/README.md)
- port: 8081
- auth: none

**Admin**
- repo: [ppf-admin-page](./ppf-admin-page/README.md)
- port: 8082
- auth: TBD

**ChatEngine**
- repo: [ppf-chat-engine](./ppf-chat-engine/README.md)
- port: 8083
- auth:
    - `GET /connect/<userId>`: `Authorization: Token <usertoken>`
    - other endpoints: `Authorization: Token <internaltoken>` 

**Payments**
- repo: [ppf-payments-api](./ppf-payments-api/README.md)
- port: 8084
- auth: `Authorization: Token <usertoken>`

## Development
**Test user**

A test user is available for development purposes.
> username: testuser
> password: mimadre
> email: test@user.try

Add the following header to your requests to authenticate as the test user:
> Authorization: Token c65b642f6712afcdc288b9d3e643aaf1301d47ab

