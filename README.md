# local-emulation
This repository hosts the following services locally:
1. PostgreSQL
1. DyanmoDB
1. DynamoDB Streams
1. Firebase Authentication

All data is persisted between emulation sessions in the `firebase` and `docker` folders. Clearing those will reset available emulated data.

# Getting Started
1.
    ```
    npm install
    ```
2.
    ```
    npm run recreate-db
    npm run start-db
    npm run start-auth
    npm run queue
    ```