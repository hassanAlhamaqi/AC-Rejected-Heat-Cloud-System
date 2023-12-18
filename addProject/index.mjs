import { DynamoDB } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocument } from "@aws-sdk/lib-dynamodb";

const dynamo = DynamoDBDocument.from(new DynamoDB());

export const handler = async (event) => {
  console.log(JSON.stringify(event.body));
  let body;
  let statusCode = "200";
  const headers = {
    "Content-Type": "application/json",
  };

  try {
    const project = JSON.parse(event.body);
    project.participants.push(project.ownerID);
    // Add the project to the Projects table
    body = await dynamo.put({
      TableName: "Projects",
      Item: project,
    });

    // Add the projectID to the projects list in the Users table
    const userUpdateParams = {
      TableName: "Users",
      Key: {
        email: project.ownerID,
      },
      UpdateExpression:
        "SET #projects = list_append(if_not_exists(#projects, :empty_list), :projectID)",
      ExpressionAttributeNames: {
        "#projects": "projects",
      },
      ExpressionAttributeValues: {
        ":projectID": [project.projectID],
        ":empty_list": [],
      },
    };

    await dynamo.update(userUpdateParams);
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
