docker kill splitsies-pg
docker kill splitsies-dynamodb

rm -rf ./docker

docker-compose -p splitsies-db up -d

# Expense tables
aws dynamodb create-table \
    --table-name Splitsies-ExpenseConnection-local \
    --attribute-definitions \
        AttributeName=connectionId,AttributeType=S \
        AttributeName=expenseId,AttributeType=S \
    --key-schema \
        AttributeName=connectionId,KeyType=HASH \
        AttributeName=expenseId,KeyType=RANGE \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
    --table-class STANDARD \
    --endpoint-url http://localhost:8000 \
    --global-secondary-indexes \
        "[
            {
                \"IndexName\": \"ExpenseIndex\",
                \"KeySchema\": [
                    {\"AttributeName\":\"expenseId\",\"KeyType\":\"HASH\"},
                    {\"AttributeName\":\"connectionId\",\"KeyType\":\"RANGE\"}
                ],
                \"Projection\":{
                    \"ProjectionType\":\"ALL\"
                },
                \"ProvisionedThroughput\": {
                    \"ReadCapacityUnits\": 5,
                    \"WriteCapacityUnits\": 5
                }
            }
        ]"

aws dynamodb create-table \
    --table-name Splitsies-ConnectionToken-local \
    --attribute-definitions \
        AttributeName=connectionId,AttributeType=S \
        AttributeName=expenseId,AttributeType=S \
    --key-schema \
        AttributeName=expenseId,KeyType=HASH \
        AttributeName=connectionId,KeyType=RANGE \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
    --table-class STANDARD \
    --endpoint-url http://localhost:8000

aws dynamodb create-table \
    --table-name Splitsies-ExpenseItem-local \
    --attribute-definitions \
        AttributeName=expenseId,AttributeType=S \
        AttributeName=id,AttributeType=S \
    --key-schema \
        AttributeName=expenseId,KeyType=HASH \
        AttributeName=id,KeyType=RANGE \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
    --table-class STANDARD \
    --endpoint-url http://localhost:8000




# User Tables
aws dynamodb create-table \
    --table-name Splitsies-User-local \
    --attribute-definitions AttributeName=id,AttributeType=S \
    --key-schema AttributeName=id,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
    --table-class STANDARD \
    --endpoint-url http://localhost:8000



# Message Queue
aws dynamodb create-table \
    --table-name Splitsies-MessageQueue-local \
    --attribute-definitions \
        AttributeName=queueName,AttributeType=S \
        AttributeName=eventId,AttributeType=S \
    --key-schema \
        AttributeName=queueName,KeyType=HASH \
        AttributeName=eventId,KeyType=RANGE \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
    --stream-specification StreamEnabled=true,StreamViewType=NEW_IMAGE \
    --endpoint-url http://localhost:8000


docker kill splitsies-pg
docker kill splitsies-dynamodb