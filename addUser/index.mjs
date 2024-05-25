import { DynamoDB } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocument } from "@aws-sdk/lib-dynamodb";

const dynamo = DynamoDBDocument.from(new DynamoDB());

export const handler = async (event) => {
  let body;
  let statusCode = "200";
  const headers = {
    "Content-Type": "application/json",
  };
  console.log(event);

  try {
    // Get the total number of items in the table
    const result = await dynamo.scan({
      TableName: "Users",
      Select: "COUNT",
    });

    const id = result.Count.toString(); // Use the count as the new id

    const { email, password, name } = JSON.parse(event.body);

    body = await dynamo.put({
      TableName: "Users",
      Item: {
        id,
        email,
        password,
        name,
        active: true,
      },
    });
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
