#!/bin/bash

local TEST_MODE_TESTING=1
local TEST_MODE_NOTTESTING=0
local test_mode="${TEST_MODE_NOTTESTING}"

function terraformat_debug() {
  local debug_msg=$1
  if [ "${test_mode}" = "${TEST_MODE_TESTING}" ]; then
    echo "${debug_msg}"
  fi
}

function terraformat() {
  local filepath=$1
  local filedir=$(dirname -- "$filepath")
  local filename=$(basename -- "$filepath")
  local extension="${filename##*.}"
  local filename_without_ext="${filename%.*}"
  local prefilepath="${filedir}/${filename_without_ext}_pre.${extension}"
  local newfilepath="${filedir}/${filename_without_ext}_new.${extension}"
  local tempfilepath="${filedir}/${filename_without_ext}_temp.tf"
  local jsonfilepath="${filedir}/${filename_without_ext}_temp.json"
  local jsonfilepath2="${filedir}/${filename_without_ext}_temp2.json"


  terraformat_debug "${newfilepath}"
  rm "${newfilepath}" 2>&1 || true

  cp "${filepath}" "${prefilepath}"

  # pre process
  perl -p -i -e 's/\`(.*)\`/"!|!$1!|!"/g' "${prefilepath}"
  perl -0777pi -e 's/\n\s*}\s*\`\s*\n/\n}\n\`\n\n/gm' "${prefilepath}"
  perl -0777pi -e 's/\`(data |resource )/\`\n$1/gm' "${prefilepath}"

  local count_begin=0
  local count_end=0

  local IGNORE="ignore"
  local HCL="hcl"
  local JSON="json"

  local state="${IGNORE}"
  local whereto="${newfilepath}"

  local escapers=( d q v s )

  while IFS="" read -r line || [ -n "$line" ]
  do
    if [ "${state}" = "${IGNORE}" ] && [[ "${line}" =~ '`{$' ]]; then
      # START of JSON (not in HCL)
      state="${JSON}"
      printf "%s\n" "${line}" >> "${newfilepath}"
      terraformat_debug "Start of JSON (not in HCL), **${line}**"

      rm "${jsonfilepath}" 2>&1 || true
      printf "{\n" >> "${jsonfilepath}"
    elif [ "${state}" = "${JSON}" ] && [[ "${line}" =~ '^[[:space:]]*`' ]]; then
      # END of JSON (not heredoc)
      state="${IGNORE}"
      terraformat_debug "End of JSON (not in HCL), **${line}**"
      #printf "}POTATO\n" >> "${jsonfilepath}"

      if [ $(cat "${jsonfilepath}" | jq empty > /dev/null 2>&1; echo $?) -eq 0 ]; then
        terraformat_debug "jq succeeded"

        # first curly is already included
        jq . "${jsonfilepath}" | tail -n +2 >> "${newfilepath}"
        printf "%s" "POTATO" >> "${newfilepath}"
      else
        terraformat_debug "jq failed"
        cat "${jsonfilepath}" >> "${newfilepath}"
      fi      

      printf "%s\n" "${line}" >> "${newfilepath}"
    elif [ "${state}" = "${IGNORE}" ] && [[ "${line}" =~ '`[[:space:]]*$' ]]; then
      # START of HCL
      state="${HCL}"
      terraformat_debug "Start of HCL, **${line}**"
      printf "%s\n" "${line}" >> "${newfilepath}"

      rm "${tempfilepath}" 2>&1 || true
      
      ((count_begin=count_begin+1))
    elif [ "${state}" = "${HCL}" ] && [[ "${line}" =~ '<<-*[A-Z]+$' ]]; then
      # START of JSON
      state="${JSON}"
      terraformat_debug "Start of JSON, **${line}**"
      printf "\n%s\n" "${line}" >> "${tempfilepath}"

      rm "${jsonfilepath}" 2>&1 || true
      end_heredoc=$(echo "${line}" | cut -d '<' -f 3)
    elif [ "${state}" = "${JSON}" ] && [[ "${line}" =~ '^[[:space:]]*'"${end_heredoc}"'[[:space:]]*$' ]]; then
      # END of JSON
      state="${HCL}"
      terraformat_debug "End of JSON, **${line}**"

      if [ $(cat "${jsonfilepath}" | jq empty > /dev/null 2>&1; echo $?) -eq 0 ]; then
        jq . "${jsonfilepath}" >> "${tempfilepath}"
      else
        cat "${jsonfilepath}" >> "${tempfilepath}"
      fi      

      printf "%s\n" "${line}" >> "${tempfilepath}"
    elif [ "${state}" = "${HCL}" ] && [[ "${line}" =~ '^[[:space:]]*`' ]]; then
      # END OF HCL
      state="${IGNORE}"
      terraformat_debug "End of HCL, **${line}**"

      perl -p -i -e 's/"\${([^}]+)}"/$1/g' "${tempfilepath}"
      perl -p -i -e 's/( +[a-z_0-9]+\s*=*\s{)/\n\n$1/g' "${tempfilepath}"
      perl -p -i -e 's/( +\s*})\n/$1\n\n/g' "${tempfilepath}"

      # escape %q, %d, %v, %[1]q, etc.
      for escape in "${escapers[@]}"; do
        perl -p -i -e 's/=\s*(%\[\d+\]'"${escape}"')(\s)/= "zzzz$1zzzz"$2/gm' "${tempfilepath}"
        perl -p -i -e 's/=\s*(%'"${escape}"')(\s)/= "zzzz$1zzzz"$2/gm' "${tempfilepath}"
        perl -p -i -e 's/=\s*\[(%\[\d+\]'"${escape}"')\]/= ["zzzz$1zzzz"]/gm' "${tempfilepath}"
        perl -p -i -e 's/=\s*\[(%'"${escape}"')\]/= ["zzzz$1zzzz"]/gm' "${tempfilepath}"
        perl -0777pi -e 's/\s*(%'"${escape}"')\s*\n/\ndata "abcd" "bdef" {\n id = "zzzz$1zzzz"\n}\n/gm' "${tempfilepath}"
        perl -0777pi -e 's/\s*(%\[\d+\]'"${escape}"')\s*\n/\ndata "abcd" "bdef" {\n id = "zzzz$1zzzz"\n}\n/gm' "${tempfilepath}"
      done

      perl -0777pi -e 's/\n{3,}/\n\n/gm' "${tempfilepath}"
      perl -0777pi -e 's/( +[a-z_0-9]+\s*=*\s{)\n\n( +[a-z_0-9]+\s*=*\s{)/$1\n$2/g' "${tempfilepath}"
      perl -0777pi -e 's/( +[a-z_0-9]+\s*=*\s{)\n\n( +[a-z_0-9]+\s*=*\s{)/$1\n$2/g' "${tempfilepath}"
      perl -0777pi -e 's/( +[a-z_0-9]+\s*=*\s{)\n\n( +[a-z_0-9]+\s*=*\s{)/$1\n$2/g' "${tempfilepath}"
      perl -0777pi -e 's/( +[a-z_0-9]+\s*=*\s{)\n\n( +[a-z_0-9]+\s*=*\s{)/$1\n$2/g' "${tempfilepath}"
      perl -0777pi -e 's/\n\s*\n(\s*}\s*)/\n$1/gm' "${tempfilepath}"
      perl -0777pi -e 's/\n\s*\n(\s*}\s*)/\n$1/gm' "${tempfilepath}"
      perl -0777pi -e 's/\n\s*\n(\s*}\s*)/\n$1/gm' "${tempfilepath}"
      perl -0777pi -e 's/\n\s*\n(\s*}\s*)/\n$1/gm' "${tempfilepath}"
      perl -0777pi -e 's/\n\s*\n(\s*\]\s*)/\n$1/gm' "${tempfilepath}"
      perl -0777pi -e 's/\n\s*\n(\s*\]\s*)/\n$1/gm' "${tempfilepath}"
      perl -0777pi -e 's/\n\s*\n(\s*\]\s*)/\n$1/gm' "${tempfilepath}"
      perl -0777pi -e 's/\n\s*\n(\s*\]\s*)/\n$1/gm' "${tempfilepath}"

      terraform fmt

      perl -0777pi -e 's/\ndata\s*"abcd"\s*"bdef"\s*{\s*id\s*=\s*"zzzz([^z]+)zzzz"\s*}/$1\n/gms' "${tempfilepath}"
      perl -p -i -e 's/"zzzz([^z]+)zzzz"/$1/gm' "${tempfilepath}"

      cat "${tempfilepath}" >> "${newfilepath}"

      printf "%s\n" "${line}" >> "${newfilepath}"      
      
      ((count_end=count_end+1))
    else
      whereto="${tempfilepath}"
      if [ "${state}" = "${IGNORE}" ]; then
        whereto="${newfilepath}"
      elif [ "${state}" = "${JSON}" ]; then
        whereto="${jsonfilepath}"
      fi

      printf "%s\n" "${line}" >> "${whereto}"
    fi
  done < "${prefilepath}"

  # post process
  perl -p -i -e 's/"!\|!(.*)!\|!"/\`$1\`/g' "${newfilepath}"
  perl -p -i -e 's/"!\|!(.*)!\|!"/\`$1\`/g' "${newfilepath}"
  perl -0777pi -e 's/\`\n\n}/\`\n}/gm' "${newfilepath}"
  perl -0777pi -e 's/\n\n\`/\n\`/gm' "${newfilepath}"
  perl -0777pi -e 's/{\n\n([^{]*{)/{\n$1/gm' "${newfilepath}"
  perl -0777pi -e 's/}\nPOTATO\`/}\`/gm' "${newfilepath}"
  perl -0777pi -e 's/\n\n\Z/\n/gm' "${newfilepath}"

  # clean up
  if [ "${test_mode}" -ne "1" ]; then
    rm "${prefilepath}" || true
    rm "${tempfilepath}" || true
    rm "${jsonfilepath}" || true
    rm "${filepath}" || true
    mv "${newfilepath}" "${filepath}"
  fi

  terraformat_debug "Begins: ${count_begin}"
  terraformat_debug "Ends: ${count_end}"
}
