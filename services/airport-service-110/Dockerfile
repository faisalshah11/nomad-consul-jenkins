FROM java:openjdk-8-alpine

RUN mkdir /app
WORKDIR /app

RUN apk update && \
    apk upgrade && \
    apk add --update ca-certificates openssl && \
    update-ca-certificates && \
    rm -rf /var/cache/apk/*

RUN wget -q https://s3-eu-west-1.amazonaws.com/devops-assesment/airports-assembly-1.1.0.jar && \
    echo "40d479396e37f61b88913ad3de3a421c75ed8f45  airports-assembly-1.1.0.jar" | sha1sum -c
    
ENTRYPOINT ["java", "-jar", "airports-assembly-1.1.0.jar"]