TARGET_ACCOUNT_ID=652907189137
USER_NAME=bartkoan
DB_USER=postgres
DB_PASSWORD=KokotinaMaster1!
DATA_SOURCE=dev/datasource/979a653c-63af-4b7a-8969-8bf9873ac2e8.json

aws quicksight create-data-source \
  --aws-account-id $TARGET_ACCOUNT_ID \
  --cli-input-json file://$DATA_SOURCE \
  --region eu-west-1 \
  --credentials '{"credentialPair": {"username": "${DB_USER}", "password": "${DB_PASSWORD}"}}' \
  --permissions '[
    {
      "Principal": "arn:aws:quicksight:eu-west-1:${TARGET_ACCOUNT_ID}:user/default/${USER_NAME}",
      "Actions": ["quicksight:DescribeDataSource","quicksight:DescribeDataSourcePermissions","quicksight:PassDataSource"]
    }
  ]'
