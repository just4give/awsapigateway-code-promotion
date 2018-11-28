#!/bin/bash
LAMBDAFUNC=myTestLambda

API_KEY_DEV=api_dev
API_KEY_PROD=api_prod

ENV_DEV=DEV
ENV_PROD=PROD

aws lambda update-function-configuration --function-name $LAMBDAFUNC --environment "Variables={API_KEY=$API_KEY_PROD,ENV=$ENV_PROD}"
VERSION=$(aws lambda publish-version --function-name $LAMBDAFUNC --query Version --output text)
aws lambda update-alias --function-name $LAMBDAFUNC --name PROD --function-version $VERSION
aws lambda update-function-configuration --function-name $LAMBDAFUNC --environment "Variables={API_KEY=$API_KEY_DEV,ENV=$ENV_DEV}"
