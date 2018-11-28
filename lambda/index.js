exports.handler = async (event) => {
    console.log(JSON.stringify(event,null,2));

    const response = {
        statusCode: 200,
        body: JSON.stringify(
            {stage: event.stageVariables.lambdaAlias, 
             apiKey: process.env.API_KEY, 
             timestamp: new Date()
            }),
    };
    return response;
};
