/**
 * queue-runner.js
 * Ties into local stream-enabled dynamoDB table and invokes lambda handlers
 */

const { DynamoDBStreamsClient, GetShardIteratorCommand, GetRecordsCommand, ListStreamsCommand, DescribeStreamCommand } = require("@aws-sdk/client-dynamodb-streams");
const { LambdaClient, InvokeCommand } = require("@aws-sdk/client-lambda");
const handlers = require("./handlers.config");

const intervalMs = 333;
const shardIterators = new Map();
const clients = new Map();

for (const endpoint of Object.keys(handlers)) {
    const lambda = new LambdaClient({
        apiVersion: '2015-03-31',
        endpoint: endpoint,
        region: "us-east-1",
        credentials: { accessKeyId: "null", secretAccessKey: "null" }
    });

    clients.set(endpoint, lambda);
}

const client = new DynamoDBStreamsClient({
    credentials: {
        accessKeyId: "null",
        secretAccessKey: "null",
    },
    region: "us-east-1",
    endpoint: "http://localhost:8000",
});

const poll = async (shardId, streamArn) => {
    try {
        if (!shardIterators.get(shardId)) {
            const iterator = await client.send(new GetShardIteratorCommand({
                ShardId: shardId,
                StreamArn: streamArn,
                ShardIteratorType: "LATEST"
            }));
        
            shardIterators.set(shardId, iterator.ShardIterator);
        }

        const result = await client.send(new GetRecordsCommand({
            ShardIterator: shardIterators.get(shardId)
        }));
    
        if (result.NextShardIterator) shardIterators.set(shardId, result.NextShardIterator);

        const invocationWorkers = [];
        result.Records = result.Records?.filter(r => r.eventName === "INSERT") ?? [];
        if (result.Records?.length) {
            for (const endpoint of Object.keys(handlers)) {
                const functions = handlers[endpoint];
                const lambdaClient = clients.get(endpoint);
                console.log({ endpoint, handlers });
                for (const [func, queueName] of functions) {
                    const event = { ...result, Records: result.Records.filter(r => r.dynamodb.Keys.queueName.S === queueName) };
                    console.log(JSON.stringify(event));
                    if (event.Records.length === 0) continue;

                    console.log(`executing ${func} with payload: ${JSON.stringify(result, null, 2)}`);
                    invocationWorkers.push(lambdaClient.send(new InvokeCommand({
                        FunctionName: func,
                        InvocationType: 'RequestResponse',
                        Payload: JSON.stringify(event),
                    })));
                }
            }
        }

        await Promise.all(invocationWorkers);
    } catch (e) {
        console.error(e);
        shardIterators.set(shardId, undefined);
    }
}

const main = async () => {
    
    const res = await client.send(new ListStreamsCommand({ TableName: "Splitsies-MessageQueue-local" }));
    const streamArn = res.Streams[0].StreamArn;

    console.log(`Running message queue with arn=${streamArn}`);

    while (true) {
        const stream = await client.send(new DescribeStreamCommand({ StreamArn: streamArn }));
        const workers = stream.StreamDescription.Shards.map(shard => poll(shard.ShardId, streamArn));
        await Promise.all(workers);
        await new Promise((resolve) => setTimeout(() => resolve(), intervalMs));
    }
}

void main();