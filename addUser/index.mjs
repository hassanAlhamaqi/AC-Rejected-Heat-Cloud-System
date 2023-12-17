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

  const { email, name, phone, projects, fieldsOfExpertise } = event.body;
  if (!email) {
    return {
      statusCode: "400",
      msg: 'primary key "email" is not provided within the body',
    };
  }
  try {
    body = await dynamo.put({
      TableName: "Users",
      Item: {
        email,
        name: name || "",
        phone: phone || "",
        projects: projects || [],
        fieldsOfExpertise: fieldsOfExpertise || [],
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
