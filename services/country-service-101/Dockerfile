FROM java:openjdk-8-alpine

RUN mkdir /app
WORKDIR /app

RUN apk update && \
    apk upgrade && \
    apk add --update ca-certificates openssl && \
    update-ca-certificates && \
    rm -rf /var/cache/apk/*

RUN wget https://s3-eu-west-1.amazonaws.com/devops-assesment/countries-assembly-1.0.1.jar && \
    echo "92bf1a691fc6dc835b21e0d74102c41ad84635f9  countries-assembly-1.0.1.jar" | sha1sum -c

ENTRYPOINT ["java", "-jar", "countries-assembly-1.0.1.jar"]