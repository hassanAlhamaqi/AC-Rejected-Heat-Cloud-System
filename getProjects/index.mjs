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
  const { name, projectID, techStack, neededFields } = requestBody;

  const filterExpressions = [];
  const expressionAttributeNames = {};
  const expressionAttributeValues = {};

  if (name) {
    filterExpressions.push("contains(#name, :name)");
    expressionAttributeNames["#name"] = "name";
    expressionAttributeValues[":name"] = name;
  }

  if (projectID) {
    filterExpressions.push("contains(#projectID, :projectID)");
    expressionAttributeNames["#projectID"] = "projectID";
    expressionAttributeValues[":projectID"] = projectID;
  }

  if (techStack) {
    filterExpressions.push("contains(techStack, :techStack)");
    expressionAttributeValues[":techStack"] = techStack;
  }

  if (neededFields) {
    filterExpressions.push("contains(neededFields, :neededFields)");
    expressionAttributeValues[":neededFields"] = neededFields;
  }

  let params = {
    TableName: "Projects",
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
