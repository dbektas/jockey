const AWS = require('aws-sdk');

const dynamoDb = new AWS.DynamoDB.DocumentClient();

exports.handler = (event, context, callback) => {
  console.info("EVENT\n" + JSON.stringify(event, null, 2))
  
  // Request body is passed in as a JSON encoded string in 'event.body'
  const data = JSON.parse(event.body);

  const params = {
    TableName: process.env.TABLE_NAME,
    // 'Key' defines the partition key and sort key of the item to be updated
    // - 'userId': Identity Pool identity id of the authenticated user
    // - 'uuId': path parameter
    Key: {
      userId: event.requestContext.identity.cognitoIdentityId,
      uuId: event.pathParameters.id
    },
    // 'UpdateExpression' defines the attributes to be updated
    // 'ExpressionAttributeValues' defines the value in the update expression
    UpdateExpression: "SET pokemon_name = :pokemon_name, pokemon_email = :pokemon_email, pokemon_type = :pokemon_type, pokemon_strength = :pokemon_strength, pokemon_desc = :pokemon_desc",
    ExpressionAttributeValues: {
      ":pokemon_name": data.pokemon_name ? data.pokemon_name :null,
      ":pokemon_email": data.pokemon_email ? data.pokemon_email :null,
      ":pokemon_type": data.pokemon_type ? data.pokemon_type : null,
      ":pokemon_strength": data.pokemon_strength ? data.pokemon_strength : null,
      ":pokemon_desc": data.pokemon_desc ? data.pokemon_desc : null
    },
    ReturnValues: "ALL_NEW"
  };

  dynamoDb.update(params, (error, data) => {
    // Set response headers to enable CORS (Cross-Origin Resource Sharing)
    const headers = {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Credentials" : true
    };

    // Return status code 500 on error
    if (error) {
      console.log(error);
      const response = {
        statusCode: 500,
        headers: headers,
        body: JSON.stringify({ status: false })
      };
      callback(null, response);
      return;
    }

    // Return status code 200 and the newly created item
    const response = {
      statusCode: 200,
      headers: headers,
      body: JSON.stringify({ status: true })
    };
    callback(null, response);
  });
};