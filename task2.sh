#!/bin/bash



original_file=${1}
output_file="output.json"


#test variables
test_name=""
#declare -A test
#declare -A summary
#lines_count=0


tests_json="[]"
summary_json="{}"

while read -r line;do 
    if [[ $line =~ "-" ]]; then
       ((lines_count++))
       continue
    fi


    if [[ $line =~ "[" ]]; then
       
        
        test_name=$(grep -o '\[[^]]*\]' <<< "$line" | sed 's/\[ \|\ ]//g')
        test_num=$(echo "$line" | grep -oE '[0-9]+ tests' | awk '{print $1}')
        tests_json="[]"
    fi


    if [[ $line =~ "command" ]]; then
        
        if [[ $line =~ "not" ]]; then
            status="false"
        else
            status="true"
            
        fi
        duration=$(echo "$line" | grep -oE '[0-9]+ms')
        name=$(echo "$line" | sed 's/^.*  //; s/, [0-9].*$//')
        test=$(./jq -n --arg name "$name" --argjson status $status --arg duration "$duration" '{name: $name, status: $status, duration: $duration}')
        tests_json=$(./jq --null-input --argjson tests_json "$tests_json" --argjson test "$test" '$tests_json + [$test]')        
        
    fi
    

    if [[ $line =~ "rated" ]]; then
     #lines_count=0
        IFS=',' read -r -a out <<< "$line"
        for item in "${out[@]}"; do
            if [[ $item == *'passed'* ]]; then
                success=$(echo "${out[0]}" | awk '{print $1}')
            elif [[ $item == *'failed'* ]]; then
                failed=$(echo "${out[1]}" | awk '{print $1}')
            elif [[ $item == *'rated'* ]]; then
                rating=$(echo "$line" | grep -oE '[0-9]+\.[0-9]+')
            elif [[ $item == *'spent'* ]]; then
                duration=$(echo "$line" | grep -oE '[0-9]+ms')
            fi
        done
    summary_json=$(./jq -n --argjson success $success --argjson failed $failed --argjson rating $rating --arg duration "$duration" '{success: $success, failed: $failed, rating: $rating, duration: $duration}')     

fi
done < "$original_file" 


output=$(./jq -n --arg testName "$test_name" --argjson tests "$tests_json" --argjson summary "$summary_json" '{testName: $testName, tests: $tests, summary: $summary}')
echo "$output" > "$output_file"


echo $test_num

echo "done"