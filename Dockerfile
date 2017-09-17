FROM debian
RUN apt-get update && apt-get install -y \
        libjson-xs-perl \
		libhtml-strip-perl \
		libwww-mechanize-perl
ADD opt /opt
ENTRYPOINT ["/usr/bin/perl", "/opt/direktnet.pl"]
