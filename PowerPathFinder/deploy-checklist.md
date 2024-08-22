# Manual deploy checklist

**Requirements:**
- have `pigz` installed
- declare variable HOST with the server's IP address


- [ ] Set the HOST variable to the server's IP address
> `export HOST=[<server_ip> | <server_hostname>]`

- [ ] Remove all existing images
> `docker rm $(docker images --format "{{.Repository}}:{{.Tag}}" | grep '^powerpathfinder')`

- [ ] Build the images
> `docker compose build --no-cache`

- [ ] Save the images and compress them
> `docker save $(docker images --format "{{.Repository}}:{{.Tag}}" | grep '^powerpathfinder') | pigz --best > powerpathfinder_images.tar.gz`

- [ ] scp the images to the server
> `scp powerpathfinder_images.tar.gz ubuntu@:/home/ubuntu/PPF/`

- [ ] scp the docker-compose file to the server
> `scp docker-compose.yml  ubuntu@ec2-18-132-64-236.eu-west-2.compute.amazonaws.com:/home/ubuntu/PPF/`

- [ ] ssh into the server
> `ssh ubuntu@ec2-18-132-64-236.eu-west-2.compute.amazonaws.com`

- [ ] Load the images
> `docker load -i powerpathfinder_images.tar.gz`

- [ ] Compose the containers
> `docker compose up -d`

## Summary

```
export HOST=ec2-13-40-58-183.eu-west-2.compute.amazonaws.com

echo "Removing all existing images"
docker rm $(docker images --format "{{.Repository}}:{{.Tag}}" | grep '^powerpathfinder')

echo "Building the images"
docker compose build --no-cache

echo "Saving the images and compressing them"
docker save $(docker images --format "{{.Repository}}:{{.Tag}}" | grep '^powerpathfinder') | pigz --best > powerpathfinder_images.tar.gz

echo "Copying the images to the server"
scp powerpathfinder_images.tar.gz docker-compose.yml ubuntu@$HOST:/home/ubuntu/PPF/

echo "Copying the docker-compose file to the server"
ssh ubuntu@$HOST
```

Once ssh into the server:
```
docker load -i powerpathfinder_images.tar.gz
docker compose up -d
```


docker compose build route-api && docker save -o route_image.tar powerpathfinder-route-api && pigz --best route_image.tar