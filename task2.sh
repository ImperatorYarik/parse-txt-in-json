#!/bin/bash



original_file=${1}
output_file="output.json"
touch "$output_file"

#test variables
test_name=""
test_arr=()
declare -A test
declare -A summary
lines_count=0
test_num=0
idx=0

while read -r line;do 
    if [[ $line =~ "-" ]]; then
       ((lines_count++))
       continue
    fi
    if [[ $line =~ "[" ]]; then
       
        
        test_name=$(grep -o '\[[^]]*\]' <<< "$line" | sed 's/\[ \|\ ]//g')
        test_num=$(echo "$line" | grep -oE '[0-9]+ tests' | awk '{print $1}')
        echo "{
 \"testName\": \"$test_name\",
 \"tests\": ["
    fi
    if [[ $line =~ "command" ]]; then
        ((idx++))
        if [[ $line =~ "not" ]]; then
            test["status"]="false"
        else
            test["status"]="true"
            
        fi
        test["value"]=$(echo "$line" | grep -oE '[0-9]+ms')
        test["name"]=$(echo "$line" | sed 's/^.*  //; s/, [0-9].*$//')
        #echo ${test["name"]}
        if [[ $idx -eq $test_num ]]; then
            echo "   {
     \"name\": \" ${test["name"]}\",
     \"status\": ${test["status"]},
     \"duration\": \"${test["value"]}\"
   }"
        else
            echo "   {
     \"name\": \" ${test["name"]}\",
     \"status\": ${test["status"]},
     \"duration\": \"${test["value"]}\"
   },"
        fi
        
    fi
    
    if [[ $lines_count -eq 2 ]]; then
     lines_count=0
        IFS=',' read -r -a out <<< "$line"
        for item in "${out[@]}"; do
            if [[ $item == *'passed'* ]]; then
                summary["success"]=$(echo "${out[0]}" | awk '{print $1}')
            elif [[ $item == *'failed'* ]]; then
                summary["failed"]=$(echo "${out[1]}" | awk '{print $1}')
            elif [[ $item == *'rated'* ]]; then
                summary["rating"]=$(echo "$line" | grep -oE '[0-9]+\.[0-9]+')
            elif [[ $item == *'spent'* ]]; then
                summary["duration"]=$(echo "$line" | grep -oE '[0-9]+ms')
            fi
        done
        echo "],
 \"summary\": {
   \"success\": ${summary["success"]},
   \"failed\": ${summary["failed"]},
   \"rating\": ${summary["rating"]},
   \"duration\": \"${summary["duration"]}\"
 }
}
        "
fi
    
done < "$original_file" >> "$output_file"
echo $test_num
echo $lines_count
echo "done"