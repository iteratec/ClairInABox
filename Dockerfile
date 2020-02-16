FROM docker:latest

VOLUME /var/run/docker.sock:/var/run/docker.sock

ENV THRESHOLD="Unknown"
#ENV PROJECT_NAME
#ENV IMAGE_TO_SCAN
#ENV IMAGE_TO_SCAN_REPO_USERNAME
#ENV IMAGE_TO_SCAN_REPO_PASSWORD
#ENV IMAGE_TO_SCAN_REPO_URL

RUN apk update && \
    apk add postgresql-client jq ruby ruby-bundler ruby-dev && \
	 gem install --no-doc mustache
COPY entrypoint.sh /entrypoint.sh
COPY jqfilter /jqfilter
COPY report.mustache /report.mustache

# TODO v12
ADD https://github.com/arminc/clair-scanner/releases/download/v8/clair-scanner_linux_amd64 clair-scanner
RUN chmod +x clair-scanner && \
    chmod +x entrypoint.sh && \
    mkdir /result

VOLUME /result

ENTRYPOINT ["/entrypoint.sh"]
