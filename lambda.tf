## Main lambda configuration
locals {
    lambda_zip_location = "outputs/anagram.zip"
}

data "archive_file" "anagram" {
 type        = "zip"
 output_path = "${local.lambda_zip_location}"
 source_file = "anagram.py"
}

resource "aws_lambda_function" "anagram_lambda" {
  filename      = local.lambda_zip_location
  function_name = "anagram_lambda_handler"
  role          = aws_iam_role.lambda_role.arn
  handler       = "anagram.anagram_lambda_handler"

  
  source_code_hash = filebase64sha256(local.lambda_zip_location)

  runtime = "python3.7"
}

# Give S3 bucket anagram-fd-testing permission to invoke our lambda function
resource "aws_s3_bucket" "anagram-bucket" {
  bucket = "anagram-fd-testing"
}

resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.anagram_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.anagram-bucket.arn
}

# Create a trigger which invokes the lambda function
# every time anagram.csv is uploaded
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.anagram-bucket.bucket

  lambda_function {
    lambda_function_arn = aws_lambda_function.anagram_lambda.arn
    events              = ["s3:ObjectCreated:Put"]
    filter_prefix       = "anagram"
    filter_suffix       = ".csv"
  }

  depends_on = [aws_lambda_permission.allow_bucket]
}