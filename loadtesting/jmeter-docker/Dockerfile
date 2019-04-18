FROM ubuntu
RUN apt-get update
RUN apt-get install -y openjdk-8-jdk openjdk-8-jre curl python python-pip
RUN pip install requests

COPY jmeter /jmeter
COPY scripts/ /loadtesting/

ENTRYPOINT /jmeter/bin/jmeter -n -t /jmeter/bin/restAPI.jmx
