import { DynamoDB } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocument } from "@aws-sdk/lib-dynamodb";

const dynamodb = new DynamoDB();
const dynamoDBDocClient = DynamoDBDocument.from(dynamodb);

export const handler = async (event) => {
  const { device_id, user_id } = JSON.parse(event.body);

  let body;
  let statusCode = 200;
  const headers = {
    "Content-Type": "application/json",
  };

  try {
    const filterExpressions = [];
    const expressionAttributeValues = {};

    if (device_id) {
      filterExpressions.push("#device_id = :device_id");
      expressionAttributeValues[":device_id"] = device_id;
    }

    if (user_id) {
      filterExpressions.push("#user_id = :user_id");
      expressionAttributeValues[":user_id"] = user_id;
    }

    const params = {
      TableName: "Logs",
      FilterExpression: filterExpressions.join(" AND "),
      ExpressionAttributeNames: {
        "#device_id": "device_id",
        "#user_id": "user_id",
      },
      ExpressionAttributeValues: expressionAttributeValues,
    };

    const result = await dynamoDBDocClient.scan(params);
    body = result.Items;
  } catch (err) {
    statusCode = 400;
    body = err.message;
  }

  return {
    statusCode,
    body: JSON.stringify(body),
    headers,
  };
};
