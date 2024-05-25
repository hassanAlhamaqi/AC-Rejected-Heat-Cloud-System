import { DynamoDB } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocument } from "@aws-sdk/lib-dynamodb";

const dynamodb = new DynamoDB();
const dynamoDBDocClient = DynamoDBDocument.from(dynamodb);

export const handler = async (event) => {
  let body;
  let statusCode = "200";
  const headers = {
    "Content-Type": "application/json",
  };

  const { id, current_water_temperature } = JSON.parse(event.body); // Extract 'id' and 'current_water_temperature' parameters

  const filterExpressions = [];
  const expressionAttributeNames = {};
  const expressionAttributeValues = {};

  if (id) {
    filterExpressions.push("contains(#id, :id)");
    expressionAttributeNames["#id"] = "id";
    expressionAttributeValues[":id"] = id;
  }

  let params = {
    TableName: "Devices",
  };

  // Check if any parameters were provided
  if (filterExpressions.length > 0) {
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

    // Update the last_online and current_water_temperature values for each item in the result
    const updatePromises = body.map(async (item) => {
      const currentDate = new Date();
      const lastOnline = currentDate.toISOString(); // Convert the date to a string

      const updateParams = {
        TableName: "Devices",
        Key: {
          id: item.id,
        },
        UpdateExpression:
          "SET last_online = :lastOnline, current_water_temperature = :temperature",
        ExpressionAttributeValues: {
          ":lastOnline": lastOnline,
          ":temperature": current_water_temperature,
        },
        ReturnValues: "ALL_NEW",
      };

      return dynamoDBDocClient.update(updateParams);
    });

    await Promise.all(updatePromises);
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
