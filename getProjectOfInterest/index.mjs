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

  const { email } = JSON.parse(event.body);

  try {
    // Get the user from the Users table
    const userParams = {
      TableName: "Users",
      Key: {
        email: email,
      },
    };

    const userResult = await dynamoDBDocClient.get(userParams);

    if (!userResult.Item) {
      statusCode = "404";
      body = "User not found in the Users table";
    } else {
      const fieldsOfExpertise = userResult.Item.fieldsOfExpertise || [];
      console.log(fieldsOfExpertise);

      // Fetch all projects from the Projects table
      const projectsParams = {
        TableName: "Projects",
      };

      const projectsResult = await dynamoDBDocClient.send(
        new ScanCommand(projectsParams)
      );

      // Filter projects based on fieldsOfExpertise
      const filteredProjects = [];

      for (const field of fieldsOfExpertise) {
        for (const project of projectsResult.Items) {
          if (
            project.neededFields &&
            project.neededFields.includes(field) &&
            !filteredProjects.includes(project)
          ) {
            filteredProjects.push(project);
          }
        }
      }

      body = filteredProjects;
    }
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
