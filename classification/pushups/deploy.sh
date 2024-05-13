docker build --platform linux/amd64 -t lambda-images:latest .
docker tag lambda-images:latest 811201412989.dkr.ecr.eu-central-1.amazonaws.com/lambda-images:latest
docker push 811201412989.dkr.ecr.eu-central-1.amazonaws.com/lambda-images:latest