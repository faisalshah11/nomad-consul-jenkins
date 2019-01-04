FROM java:openjdk-8-alpine

RUN mkdir /app
WORKDIR /app

RUN apk update && \
    apk upgrade && \
    apk add --update ca-certificates openssl && \
    update-ca-certificates && \
    rm -rf /var/cache/apk/* 
    
RUN wget -q https://s3-eu-west-1.amazonaws.com/devops-assesment/airports-assembly-1.0.1.jar  &&  \
    echo "0bd35ea555b9aabaf30d255f3cb90aedf6bebca1  airports-assembly-1.0.1.jar" | sha1sum -c

ENTRYPOINT ["java"," -jar", "airports-assembly-1.0.1.jar"]