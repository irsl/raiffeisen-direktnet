FROM debian
RUN apt-get update && apt-get install -y \
        libjson-xs-perl \
		libhtml-strip-perl \
		libfile-slurp-perl \
		libwww-mechanize-perl \
		&& && rm -rf /var/lib/apt/lists/*
USER 23101:23101
ADD opt /opt
ENTRYPOINT ["/usr/bin/perl", "/opt/direktnet.pl"]
