FROM java:openjdk-8-alpine

RUN mkdir /app
WORKDIR /app

RUN apk update && \
    apk upgrade && \
    apk add --update ca-certificates openssl && \
    update-ca-certificates && \
    wget https://s3-eu-west-1.amazonaws.com/devops-assesment/airports-assembly-1.0.1.jar -O /app/airports-assembly-1.0.1.jar && \
    rm -rf /var/cache/apk/*

ENTRYPOINT ["java"," -jar", " airports-assembly-1.0.1.jar"]