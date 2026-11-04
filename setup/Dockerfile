FROM alpine:3.22
# gum = pretty prompts, openssl = key generation
RUN apk add --no-cache gum openssl
WORKDIR /project
CMD ["sh", "setup/setup.sh"]