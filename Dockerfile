"FROM tomcat:10-jdk17" 
"COPY web /usr/local/tomcat/webapps/ROOT" 
"EXPOSE 8080" 
"CMD [\"catalina.sh\", \"run\"]" 
