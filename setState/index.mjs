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
  const {
    device_id,
    user_id,
    desired_ac_temperature,
    desired_water_temperature,
    ac_state,
    heater_state,
    automate,
  } = requestBody;

  try {
    // Check if the device_id exists in the Devices table
    const deviceParams = {
      TableName: "Devices",
      Key: {
        id: device_id,
      },
    };

    const deviceResult = await dynamoDBDocClient.get(deviceParams);

    if (!deviceResult.Item) {
      statusCode = "404";
      body = "Device ID not found in the Devices table";
    } else {
      const {
        user_id: loggedUserId,
        ac_state: old_ac_state,
        heater_state: old_heater_state,
      } = deviceResult.Item;
      if (loggedUserId !== user_id) {
        statusCode = "403";
        body = "Unauthorized user";
      } else {
        // Update the desired_ac_temperature, desired_water_temperature, ac_state, heater_state, and automate values in the Devices table
        const updateParams = {
          TableName: "Devices",
          Key: {
            id: device_id,
          },
          UpdateExpression:
            "SET desired_ac_temperature = :acTemp, desired_water_temperature = :waterTemp, ac_state = :acState, heater_state = :heaterState, automate = :automateValue", // Updated attribute names
          ExpressionAttributeValues: {
            ":acTemp": desired_ac_temperature, // Updated attribute name
            ":waterTemp": desired_water_temperature, // Updated attribute name
            ":acState": ac_state,
            ":heaterState": heater_state,
            ":automateValue": automate, // Updated parameter name
          },
          ReturnValues: "ALL_NEW",
        };

        const updateResult = await dynamoDBDocClient.update(updateParams);

        body = updateResult.Attributes;

        /*if (old_ac_state !== ac_state) {
          body = "new ac state!"
        }
        if (old_heater_state !== heater_state) {
          body = "new heater state!"
        }
        */

        // Get the size of the Logs table
        const logsTableParams = {
          TableName: "Logs",
          Select: "COUNT",
        };

        const logsTableResult = await dynamoDBDocClient.scan(logsTableParams);
        const logsTableSize = logsTableResult.Count;

        // Save values in the Logs table
        const logParams = {
          TableName: "Logs",
          Item: {
            id: "" + logsTableSize,
            user_id,
            device_id,
            desired_ac_temperature,
            desired_water_temperature,
            ac_state,
            heater_state,
            timestamp: new Date().toISOString(),
          },
        };

        await dynamoDBDocClient.put(logParams);
      }
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
