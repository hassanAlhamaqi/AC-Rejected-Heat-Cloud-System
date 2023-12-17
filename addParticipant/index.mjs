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

  const requestBody = event.body;
  const { projectID, email } = requestBody;

  try {
    // Check if the email exists in the Users table
    const userParams = {
      TableName: "Users",
      Key: {
        email: email,
      },
    };

    const userResult = await dynamoDBDocClient.get(userParams);

    if (!userResult.Item) {
      statusCode = "404";
      body = "Email not found in the Users table";
    } else {
      // Add the email to the participants list in the Projects table
      const projectParams = {
        TableName: "Projects",
        Key: {
          projectID: projectID,
        },
        UpdateExpression:
          "SET #participants = list_append(if_not_exists(#participants, :empty_list), :email)",
        ExpressionAttributeNames: {
          "#participants": "participants",
        },
        ExpressionAttributeValues: {
          ":email": [email],
          ":empty_list": [],
        },
        ReturnValues: "ALL_NEW",
      };

      const projectResult = await dynamoDBDocClient.update(projectParams);

      // Add the projectID to the projects list in the Users table
      const userUpdateParams = {
        TableName: "Users",
        Key: {
          email: email,
        },
        UpdateExpression:
          "SET #projects = list_append(if_not_exists(#projects, :empty_list), :projectID)",
        ExpressionAttributeNames: {
          "#projects": "projects",
        },
        ExpressionAttributeValues: {
          ":projectID": [projectID],
          ":empty_list": [],
        },
      };

      await dynamoDBDocClient.update(userUpdateParams);

      body = projectResult.Attributes;
    }
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
