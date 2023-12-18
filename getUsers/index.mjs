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

  const { name, email, fieldsOfExpertise } = JSON.parse(event.body);

  try {
    let scanParams = {
      TableName: "Users",
    };

    // Check if any parameters were provided
    if (name || email || fieldsOfExpertise) {
      const filterExpressions = [];
      const expressionAttributeNames = {};
      const expressionAttributeValues = {};

      if (name) {
        filterExpressions.push("contains(#n, :name)");
        expressionAttributeNames["#n"] = "name";
        expressionAttributeValues[":name"] = name;
      }

      if (email) {
        filterExpressions.push("contains(#e, :email)");
        expressionAttributeNames["#e"] = "email";
        expressionAttributeValues[":email"] = email;
      }

      if (fieldsOfExpertise && fieldsOfExpertise.length > 0) {
        filterExpressions.push("contains(#foe, :field)");
        expressionAttributeNames["#foe"] = "fieldsOfExpertise";
        expressionAttributeValues[":field"] = fieldsOfExpertise[0]; // Assuming only one field is provided
      }

      scanParams.FilterExpression = filterExpressions.join(" AND ");
      scanParams.ExpressionAttributeNames = expressionAttributeNames;
      scanParams.ExpressionAttributeValues = expressionAttributeValues;
    }

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
