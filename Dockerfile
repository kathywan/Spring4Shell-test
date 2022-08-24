# Lacework Agent: adding a build stage
FROM lacework/datacollector:latest-sidecar AS agent-build-image

# Pin our tomcat version to something that has not been updated to remove the vulnerability
# https://hub.docker.com/layers/tomcat/library/tomcat/9.0.59-jdk11/images/sha256-383a062a98c70924fb1b1da391a054021b6448f0aa48860ae02f786aa5d4e2ad?context=explore
FROM lunasec/tomcat-9.0.59-jdk11

ADD src/ /helloworld/src
ADD pom.xml /helloworld

#  Build spring app
RUN apt update && apt install maven -y
WORKDIR /helloworld/
RUN mvn clean package

#  Deploy to tomcat
RUN mv target/helloworld.war /usr/local/tomcat/webapps/

# Lacework Agent: copying the binary
COPY --from=agent-build-image /var/lib/lacework-backup /var/lib/lacework-backup

# Lacework Agent: setting up configurations  
RUN  --mount=type=secret,id=LW_AGENT_ACCESS_TOKEN  \
  mkdir -p /var/lib/lacework/config &&             \
  echo '{"tokens": {"accesstoken": "'$(cat /run/secrets/LW_AGENT_ACCESS_TOKEN)'"}}' > /var/lib/lacework/config/config.json

EXPOSE 8080
ENTRYPOINT ["/var/lib/lacework-backup/lacework-sidecar.sh"]
CMD ["catalina.sh", "run"]
