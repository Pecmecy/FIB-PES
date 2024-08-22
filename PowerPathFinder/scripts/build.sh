touch .env
docker compose -f "docker-compose.yml" build

echo "Saving images to images.tar.gz"
docker save "ppf-chat-engine" "ppf-payments-api" "ppf-user-api" "ppf-route-api" "ppf-admin-page" | gzip > images.tar.gz

echo "Copying images.tar.gz to EC2 instance"
scp -i "ppf-ec2-keys.pem" images.tar.gz ubuntu@ec2-18-132-64-236.eu-west-2.compute.amazonaws.com:~/PPF

echo "Copying docker-compose.yml to EC2 instance"
scp -i "ppf-ec2-keys.pem" docker-compose.yml ubuntu@ec2-18-132-64-236.eu-west-2.compute.amazonaws.com:~/PPF

rm .env

echo scp into EC2 instance and run the following commands:
echo "cd PPF"
echo "docker load -i images.tar.gz"
echo "docker compose up -d"
