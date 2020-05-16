const AWS = require('aws-sdk');

const dynamoDb = new AWS.DynamoDB.DocumentClient();

exports.handler = (event, context, callback) => {
  console.info("EVENT\n" + JSON.stringify(event, null, 2))
  
  // Request body is passed in as a JSON encoded string in 'event.body'
  const data = JSON.parse(event.body);

  const params = {
    TableName: process.env.TABLE_NAME,
    // 'Item' contains the attributes of the item to be created
    // - 'userId': user identities are federated through the
    //             Cognito Identity Pool, we will use the identity id
    //             as the user id of the authenticated user
    // - 'uuId': a unique uuid
    // - 'pokemon_name': parsed from request body - pokemon name of the item
    // - 'pokemon_email': parsed from request body - pokemon email of the item
    // - 'pokemon_type': parsed from request body - pokemon type of the item
    // - 'pokemon_strength': parsed from request body - pokemon strength of the item
    // - 'pokemon_desc': parsed from request body - pokemon description of the item
    // - 'createdAt': current Unix timestamp
    Item: {
      userId: event.requestContext.identity.cognitoIdentityId,
      uuId: context.awsRequestId,
      pokemon_name: data.pokemon_name,
      pokemon_email: data.pokemon_email,
      pokemon_type: data.pokemon_type,
      pokemon_strength: data.pokemon_strength,
      pokemon_desc: data.pokemon_desc,
      createdAt: Date.now()
    }
  };

  dynamoDb.put(params, (error, data) => {
    // Set response headers to enable CORS (Cross-Origin Resource Sharing)
    const headers = {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Credentials" : true
    };

    // Return status code 500 on error
    if (error) {
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
}