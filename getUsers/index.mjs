import { DynamoDB } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocument, ScanCommand } from "@aws-sdk/lib-dynamodb";

const dynamoDB = new DynamoDB();
const dynamoDBDocClient = DynamoDBDocument.from(dynamoDB);

export const handler = async (event) => {
  console.log(JSON.stringify(event.body));
  let body;
  let statusCode = "200";
  const headers = {
    "Content-Type": "application/json",
  };

  const { email, password } = JSON.parse(event.body);

  try {
    let scanParams = {
      TableName: "Users",
      FilterExpression: "#email = :email and #password = :password",
      ExpressionAttributeNames: {
        "#email": "email",
        "#password": "password",
      },
      ExpressionAttributeValues: {
        ":email": email,
        ":password": password,
      },
    };

    const scanCommand = new ScanCommand(scanParams);
    const scanResult = await dynamoDBDocClient.send(scanCommand);

    body = scanResult.Items;
  } catch (err) {
    statusCode = "400";
    body = err.message;
  }

  return {
    statusCode,
    body: JSON.stringify(body),
    headers,
  };
};
