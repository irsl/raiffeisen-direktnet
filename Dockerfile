FROM debian
USER 23101:23101
RUN apt-get update && apt-get install -y \
        libjson-xs-perl \
		libhtml-strip-perl \
		libfile-slurp-perl \
		libwww-mechanize-perl
ADD opt /opt
ENTRYPOINT ["/usr/bin/perl", "/opt/direktnet.pl"]
