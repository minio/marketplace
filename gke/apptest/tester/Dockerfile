FROM ubuntu:20.04

# Install ca-certificates
RUN apt update && apt upgrade -y && apt install -y ca-certificates netbase curl

COPY ./test.sh /test.sh

ENTRYPOINT ["/test.sh"]
