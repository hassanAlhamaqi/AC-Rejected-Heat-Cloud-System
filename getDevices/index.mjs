import { DynamoDB } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocument } from "@aws-sdk/lib-dynamodb";

const dynamodb = new DynamoDB();
const dynamoDBDocClient = DynamoDBDocument.from(dynamodb);

export const handler = async (event) => {
  console.log(JSON.stringify(event.body));
  let body;
  let statusCode = "200";
  const headers = {
    "Content-Type": "application/json",
  };

  const requestBody = JSON.parse(event.body);
  const { user_id } = requestBody; // Extract 'user_id' parameter

  const filterExpressions = [];
  const expressionAttributeNames = {};
  const expressionAttributeValues = {};

  if (user_id) {
    filterExpressions.push("contains(#user_id, :user_id)");
    expressionAttributeNames["#user_id"] = "user_id";
    expressionAttributeValues[":user_id"] = user_id;
  }

  let params = {
    TableName: "Devices",
  };

  // Check if user_id parameter was provided
  if (user_id) {
    params = {
      ...params,
      FilterExpression: filterExpressions.join(" AND "),
      ExpressionAttributeNames: expressionAttributeNames,
      ExpressionAttributeValues: expressionAttributeValues,
    };
  }

  try {
    const result = await dynamoDBDocClient.scan(params);
    body = result.Items;
  } catch (err) {
    statusCode = "400";
    body = err.message;
  } finally {
    body = JSON.stringify(body);
  }

  return {
    statusCode,
    body,
    headers,
  };
};
