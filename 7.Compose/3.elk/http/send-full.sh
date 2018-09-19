while read -r line; do curl -XPUT -d "$line" http://localhost:8080 ; done < ./nginx-full.log
