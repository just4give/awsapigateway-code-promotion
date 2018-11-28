#!/bin/bash
LAMBDAFUNC=myTestLambda
rm -rf ./build
mkdir build && cd build
cp ../lambda/index.js index.js
cp -R ../lambda/node_modules .


zip -X -r index.zip *.js node_modules

aws lambda update-function-code --function-name $LAMBDAFUNC --zip-file fileb://index.zip