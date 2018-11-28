# awsapigateway-code-promotion
This repo contains code to explain code promotion process for AWS Apigateway

## Build AWS resources using terraform 
Buidling AWS resources manually one after another can be a horrible job and maintainance nightmare. We need to create lot of resources to build single REST API endpoint such as lambda function, aliases, api gateway , apigateway DEV and PROD stages, grant persmission to api gateway to access lambda aliases. Things get more complicated when you need to re-create same resources multiple time. Always there is a possibility you will forget one little thing and you will end up wasting entire day to figure it out. To be a smart kid, you would like to script your infrastructure so that you can run the same scripts and always get same infrasturcture created. 
For this excercise we will create all our resources using terraform. Learn more about terraform and installation guide visit https://www.terraform.io/

Once you have terraform installed, execute below commands which will do everything needed for you to get started with this excercise. 

```
cd terraform
terraform init
terraform plan --var-file=variables.tfvars
```
Above command will output all the resources terraform is going to create on your behalf. Take a close look at them and if you are fine, execute below command which will actually create the respurces for you.
<img width="851" alt="screen shot 2018-11-28 at 4 13 08 pm" src="https://user-images.githubusercontent.com/9275193/49183324-9d6ad380-f32a-11e8-85ae-343d610df195.png">

```
terraform apply --var-file=variables.tfvars --auto-approve
```
<img width="910" alt="screen shot 2018-11-28 at 4 14 14 pm" src="https://user-images.githubusercontent.com/9275193/49183410-d60aad00-f32a-11e8-880f-064c8d8cb9d0.png">

At this point, your REST API is deployed and ready to be tested. Above command will print two endpints - one for dev and another for prod. Now copy one of them and call it using curl (or paste on browser)

```
curl <copied_url>/todos
```
You should get a response back like below

```
{
  "stage": "DEV",
  "apiKey": "api_dev",
  "timestamp": "2018-11-28T16:16:55.301Z"
}
```
At this point, both DEV and PROD aliases pointing to $LATEST version of myTestLambda function. 

Execute below script to create a new version and update prod alias

```
sh promote-lambda-prod.sh
```
Now your production API is pointing to immutable lambda version and you are ready to start your development which should not impact your prod APIs anymore. Makse some changes to your lambda code ( ./lambda/index.js) and deploy changes to dev executing below command

```
sh deploy-lambda-dev.sh
```
You will notice your new changes are available only in your dev REST APIs leaving prod untouched. When your are done with testing and ready to promote your code to prodiction execute promote-lambda-prod shell script. 
