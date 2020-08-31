#!/bin/bash

local TEST_MODE_TESTING=1
local TEST_MODE_NOTTESTING=0

function terraformat_debug() {
  local debug_msg=$1
  if [ "${TERRAFORMAT_TEST_MODE}" = "${TEST_MODE_TESTING}" ]; then
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
  local hclfilepath="${filedir}/${filename_without_ext}_temp.tf"
  local jsonfilepath="${filedir}/${filename_without_ext}_temp.json"
  local yamlfilepath="${filedir}/${filename_without_ext}_temp.yaml"

  if [ "${TERRAFORMAT_TEST_MODE}" = "" ]; then
    TERRAFORMAT_TEST_MODE="${TEST_MODE_TESTING}"
  fi

  printf "Format: %s\n" "${filepath}"

  local error_count=0

  rm -f "${newfilepath}" 2>&1 || true

  cp "${filepath}" "${prefilepath}"

  # pre process
  perl -p -i -e 's/\`(.*)\`/"!|!$1!|!"/g' "${prefilepath}"
  perl -0777pi -e 's/\n\s*}\s*\`\s*\n/\n}\n\`\n\n/gm' "${prefilepath}"
  perl -0777pi -e 's/}\s*\`/}\n\`/gm' "${prefilepath}"
  perl -0777pi -e 's/\`(data |resource |variable |tags =)/\`\n$1/gm' "${prefilepath}"
  perl -p -i -e 's/\`([a-z].*?{)/\`\n$1/g' "${prefilepath}"
  perl -0777pi -e 's/\`\s+{/\`{/g' "${prefilepath}"

  # two step process to move away from single-line JSON
  perl -p -i -e 's/(?<!\\)"(.*\\".*\\".*)(?<!\\)"/#HÄRDOK_BÖRJA#$1#HÄRDOK_SLUTET#/g' "${prefilepath}"

  local heredoc_oneliner=""
  local find_heredoc_oneliner='(#HÄRDOK_BÖRJA#.*)\\"(.*)\\"(.*#HÄRDOK_SLUTET#)'
  while :
  do
    heredoc_oneliner=""
    heredoc_oneliner=$(perl -ne 'print "$&\n" if /'"${find_heredoc_oneliner}"'/' "${prefilepath}")
    if [ "${heredoc_oneliner}" = "" ]; then
      break
    fi
    perl -p -i -e 's/'"${find_heredoc_oneliner}"'/$1"$2"$3/g' "${prefilepath}"
  done

  perl -p -i -e 's/#HÄRDOK_BÖRJA#(.*)#HÄRDOK_SLUTET#/<<EOF\n$1\nEOF\n/g' "${prefilepath}"

  # mark YAML
  perl -0777pi -e 's/(<<-?[A-Z]+)(\n[a-zA-Z][a-zA-Z0-9]+:([^\n:]*)\n[ \t]+[A-Z][a-zA-Z0-9]+:)/$1##YAML##$2/g' "${prefilepath}"
  perl -0777pi -e 's/\`(\n[a-zA-Z][a-zA-Z0-9]+:[^\n:]*\n[ \t]*[a-zA-Z0-9]+:)/\`##YAML##$1/g' "${prefilepath}"
  perl -0777pi -e 's/(\`##YAML##.*?)(\`)/$1\n$2/gs' "${prefilepath}"
  
  # opening & closing curlies
  perl -p -i -e 's/^([\t ]*#.*){/$1#ÖPPNAR_LOCKIGT#/gm' "${prefilepath}"
  perl -p -i -e 's/^([\t ]*#.*){/$1#ÖPPNAR_LOCKIGT#/gm' "${prefilepath}"
  perl -p -i -e 's/^([\t ]*#.*){/$1#ÖPPNAR_LOCKIGT#/gm' "${prefilepath}"

  perl -p -i -e 's/^([\t ]*#.*)}/$1#STÄNGT_LOCKIGT#/gm' "${prefilepath}"
  perl -p -i -e 's/^([\t ]*#.*)}/$1#STÄNGT_LOCKIGT#/gm' "${prefilepath}"
  perl -p -i -e 's/^([\t ]*#.*)}/$1#STÄNGT_LOCKIGT#/gm' "${prefilepath}"

  perl -p -i -e 's/("[^"]*){([^"]*")/$1#ÖPPNAR_LOCKIGT#$2/g' "${prefilepath}"
  perl -p -i -e 's/("[^"]*){([^"]*")/$1#ÖPPNAR_LOCKIGT#$2/g' "${prefilepath}"
  perl -p -i -e 's/("[^"]*){([^"]*")/$1#ÖPPNAR_LOCKIGT#$2/g' "${prefilepath}"
  perl -p -i -e 's/("[^"]*){([^"]*")/$1#ÖPPNAR_LOCKIGT#$2/g' "${prefilepath}"
  perl -p -i -e 's/("[^"]*){([^"]*")/$1#ÖPPNAR_LOCKIGT#$2/g' "${prefilepath}"

  perl -p -i -e 's/("[^"]*)}([^"]*")/$1#STÄNGT_LOCKIGT#$2/g' "${prefilepath}"
  perl -p -i -e 's/("[^"]*)}([^"]*")/$1#STÄNGT_LOCKIGT#$2/g' "${prefilepath}"
  perl -p -i -e 's/("[^"]*)}([^"]*")/$1#STÄNGT_LOCKIGT#$2/g' "${prefilepath}"
  perl -p -i -e 's/("[^"]*)}([^"]*")/$1#STÄNGT_LOCKIGT#$2/g' "${prefilepath}"
  perl -p -i -e 's/("[^"]*)}([^"]*")/$1#STÄNGT_LOCKIGT#$2/g' "${prefilepath}"

  local count_begin=0
  local count_end=0

  local IGNORE="ignore"
  local HCL="hcl"
  local JSON="json"
  local YAML="yaml"

  local state="${IGNORE}"
  local whereto="${newfilepath}"

  local line_num=0

  while IFS="" read -r line || [ -n "$line" ]
  do
    ((line_num=line_num+1))
    if [ "${state}" = "${IGNORE}" ] && [[ "${line}" =~ '`##YAML##[[:space:]]*$' ]]; then
      # START of YAML not in HCL
      state="${YAML}"
      terraformat_debug "Start of YAML not in HCL, ${line_num}: **${line}**"
      printf "%s\n" "${line}" >> "${newfilepath}"

      rm -f "${yamlfilepath}" 2>&1 || true

    elif [ "${state}" = "${YAML}" ] && [[ "${line}" =~ '`' ]]; then
      # END of YAML not in HCL
      state="${IGNORE}"
      terraformat_debug "End of YAML not in HCL, ${line_num}: **${line}**"

      perl -p -i -e 's/(?<!"\${)#ÖPPNAR_LOCKIGT#/{/g' "${yamlfilepath}"
      perl -p -i -e 's/#STÄNGT_LOCKIGT#(?!}")/}/g' "${yamlfilepath}"
      perl -p -i -e 's/(?<!~)%(\[\d+\])?(d|s|q|v|t|f)/~~%$1$2/g' "${yamlfilepath}"

      # escape interpo string within YAML
      perl -p -i -e 's/\${([^}]+)}/\$-{$1}-/g' "${yamlfilepath}"

      perl -p -i -e 's/~~%/%/g' "${yamlfilepath}"      

      if [ $(prettier --check "${yamlfilepath}" > /dev/null 2>&1; echo $?) -ne 2 ]; then
        terraformat_debug "    prettier succeeded"
        prettier --write "${yamlfilepath}"
        cat "${yamlfilepath}" >> "${newfilepath}"
      else
        terraformat_debug "    prettier failed"
        cat "${yamlfilepath}" >> "${newfilepath}"
      fi

      printf "%s\n" "${line}" >> "${newfilepath}"

    elif [ "${state}" = "${IGNORE}" ] && [[ "${line}" =~ '`{[[:space:]]*$' ]]; then
      # START of JSON not in HCL
      state="${JSON}"
      printf "%s\n" "${line}" >> "${newfilepath}"
      terraformat_debug "Start of JSON not in HCL, ${line_num}: **${line}**"

      rm -f "${jsonfilepath}" 2>&1 || true
      printf "{\n" >> "${jsonfilepath}"
    elif [ "${state}" = "${JSON}" ] && [[ "${line}" =~ '^[[:space:]]*`' ]]; then
      # END of JSON (not heredoc)
      state="${IGNORE}"
      terraformat_debug "End of JSON not in HCL, ${line_num}: **${line}**"

      perl -p -i -e 's/(?<!"\${)#ÖPPNAR_LOCKIGT#/{/g' "${jsonfilepath}"
      perl -p -i -e 's/#STÄNGT_LOCKIGT#(?!}")/}/g' "${jsonfilepath}"

      if [ $(cat "${jsonfilepath}" | jq empty > /dev/null 2>&1; echo $?) -eq 0 ]; then
        terraformat_debug "    jq succeeded"

        # first curly is already included
        jq . "${jsonfilepath}" | tail -n +2 >> "${newfilepath}"
        printf "%s" "POTATO" >> "${newfilepath}"
      else
        terraformat_debug "    jq failed"
        cat "${jsonfilepath}" >> "${newfilepath}"
      fi

      printf "%s\n" "${line}" >> "${newfilepath}"
    elif [ "${state}" = "${IGNORE}" ] && [[ "${line}" =~ '`[[:space:]]*$' ]]; then
      # START of HCL
      state="${HCL}"
      terraformat_debug "Start of HCL, ${line_num}: **${line}**"
      printf "%s\n" "${line}" >> "${newfilepath}"

      rm -f "${hclfilepath}" 2>&1 || true

      ((count_begin=count_begin+1))
    elif [ "${state}" = "${HCL}" ] && [[ "${line}" =~ '<<-*[A-Z]+##YAML##$' ]]; then
      # START of YAML in HCL
      state="${YAML}"
      terraformat_debug "Start of YAML (in HCL), ${line_num}: **${line}**"
      printf "\n%s\n" "${line}" >> "${hclfilepath}"

      rm -f "${yamlfilepath}" 2>&1 || true
      end_heredoc=$(echo "${line}" | cut -d'<' -f 3 | cut -d'-' -f 2 | cut -d'#' -f 1)
      terraformat_debug "    End heredoc will be: **${end_heredoc}**"
    elif [ "${state}" = "${HCL}" ] && [[ "${line}" =~ '<<-*[A-Z]+$' ]]; then
      # START of JSON in HCL
      state="${JSON}"
      terraformat_debug "Start of JSON (in HCL), ${line_num}: **${line}**"
      printf "\n%s\n" "${line}" >> "${hclfilepath}"

      rm -f "${jsonfilepath}" 2>&1 || true
      end_heredoc=$(echo "${line}" | cut -d'<' -f 3 | cut -d'-' -f 2)
      terraformat_debug "    End heredoc will be: **${end_heredoc}**"
    elif [ "${state}" = "${YAML}" ] && [[ "${line}" =~ '^[[:space:]]*'"${end_heredoc}"'[[:space:]]*$' ]]; then
      # END of YAML in HCL
      state="${HCL}"
      terraformat_debug "End of YAML (in HCL), ${line_num}: **${line}**"

      perl -p -i -e 's/(?<!"\${)#ÖPPNAR_LOCKIGT#/{/g' "${yamlfilepath}"
      perl -p -i -e 's/#STÄNGT_LOCKIGT#(?!}")/}/g' "${yamlfilepath}"
      perl -p -i -e 's/(?<!~)%(\[\d+\])?(d|s|q|v|t|f)/~~%$1$2/g' "${yamlfilepath}"

      # escape interpo string within YAML
      perl -p -i -e 's/"\${([^}]+)}"/"\$-{$1}-"/g' "${yamlfilepath}"

      if [ $(prettier --check "${yamlfilepath}" > /dev/null 2>&1; echo $?) -ne 2 ]; then
        terraformat_debug "    prettier succeeded"
        prettier --write "${yamlfilepath}"
        cat "${yamlfilepath}" >> "${hclfilepath}"
      else
        terraformat_debug "    prettier failed"
        cat "${yamlfilepath}" >> "${hclfilepath}"
      fi

      printf "%s\n##NY_LINJE##\n" "${line}" >> "${hclfilepath}"
    elif [ "${state}" = "${JSON}" ] && [[ "${line}" =~ '^[[:space:]]*'"${end_heredoc}"'[[:space:]]*$' ]]; then
      # END of JSON in HCL
      state="${HCL}"
      terraformat_debug "End of JSON (in HCL), ${line_num}: **${line}**"

      perl -p -i -e 's/(?<!"\${)#ÖPPNAR_LOCKIGT#/{/g' "${jsonfilepath}"
      perl -p -i -e 's/#STÄNGT_LOCKIGT#(?!}")/}/g' "${jsonfilepath}"

      # escape interpo string within JSON
      perl -p -i -e 's/"\${([^}]+)}"/"\$-{$1}-"/g' "${jsonfilepath}"

      if [ $(cat "${jsonfilepath}" | jq empty > /dev/null 2>&1; echo $?) -eq 0 ]; then
        terraformat_debug "    jq succeeded"
        jq . "${jsonfilepath}" >> "${hclfilepath}"
      else
        terraformat_debug "    jq failed"
        cat "${jsonfilepath}" >> "${hclfilepath}"
      fi

      printf "%s\n##NY_LINJE##\n" "${line}" >> "${hclfilepath}"
    elif [ "${state}" = "${HCL}" ] && [[ "${line}" =~ '^[[:space:]]*`' ]]; then
      # END OF HCL
      state="${IGNORE}"
      terraformat_debug "End of HCL, ${line_num}: **${line}**"

      # "${aws_subnet.test.*.id[0]}" ==> aws_subnet.test[0].id
      perl -p -i -e 's/"\$#ÖPPNAR_LOCKIGT#([a-z0-9_-]+\.[a-z0-9_-]+)\.\*(\.[a-z0-9_-]+)(\[\d+\])#STÄNGT_LOCKIGT#"/$1$3$2/g' "${hclfilepath}"
      perl -p -i -e 's/"\$#ÖPPNAR_LOCKIGT#([^Ä]+)#STÄNGT_LOCKIGT#"/$1/g' "${hclfilepath}"
      
      perl -0777pi -e 's/^([ \t]+[a-z_0-9]+\s*=*\s{)/\n\n$1/gm' "${hclfilepath}"
      perl -0777pi -e 's/^([ \t]+})\n/$1\n\n/gm' "${hclfilepath}"
      
      # escape %q, %d, %v, %[1]q, etc.
      # (?<!~)%(d|s|q|v|t|f) - negative lookbehind to avoid ~%
      # "([^"]*)(?<!~)%(d|s|q|v|t|f)([^"]*)"

      # %d, etc. within quotes - up to 5 replaced (1 per iter) in a single, quoted phrase
      perl -p -i -e 's/"([^"]*)(?<!~)%(\[\d+\])?(d|s|q|v|t|f)([^"]*)"/"$1~~%$2$3$4"/g' "${hclfilepath}"
      perl -p -i -e 's/"([^"]*)(?<!~)%(\[\d+\])?(d|s|q|v|t|f)([^"]*)"/"$1~~%$2$3$4"/g' "${hclfilepath}"
      perl -p -i -e 's/"([^"]*)(?<!~)%(\[\d+\])?(d|s|q|v|t|f)([^"]*)"/"$1~~%$2$3$4"/g' "${hclfilepath}"
      perl -p -i -e 's/"([^"]*)(?<!~)%(\[\d+\])?(d|s|q|v|t|f)([^"]*)"/"$1~~%$2$3$4"/g' "${hclfilepath}"
      perl -p -i -e 's/"([^"]*)(?<!~)%(\[\d+\])?(d|s|q|v|t|f)([^"]*)"/"$1~~%$2$3$4"/g' "${hclfilepath}"

      # %d, etc. within [] - up to 5 replaced (1 per iter) in a single phrase
      perl -p -i -e 's/\[(.*)(?<!~)%(\[\d+\])?(d|s|q|v|t|f)(.*)\]/[$1"~~~%$2$3~"$4]/g' "${hclfilepath}"
      perl -p -i -e 's/\[(.*)(?<!~)%(\[\d+\])?(d|s|q|v|t|f)(.*)\]/[$1"~~~%$2$3~"$4]/g' "${hclfilepath}"
      perl -p -i -e 's/\[(.*)(?<!~)%(\[\d+\])?(d|s|q|v|t|f)(.*)\]/[$1"~~~%$2$3~"$4]/g' "${hclfilepath}"
      perl -p -i -e 's/\[(.*)(?<!~)%(\[\d+\])?(d|s|q|v|t|f)(.*)\]/[$1"~~~%$2$3~"$4]/g' "${hclfilepath}"
      perl -p -i -e 's/\[(.*)(?<!~)%(\[\d+\])?(d|s|q|v|t|f)(.*)\]/[$1"~~~%$2$3~"$4]/g' "${hclfilepath}"

      perl -p -i -e 's/(?<!~)%(\[\d+\])(d|s|q|v|t|f)\s*=(.*)\n/ÖÖÖÖÖ =$3 #~%$1$2\n/g' "${hclfilepath}"
      perl -p -i -e 's/(?<!~)%(d|s|q|v|t|f)\s*=(.*)\n/ÖÖ =$2 #~%$1\n/g' "${hclfilepath}"
      perl -p -i -e 's/=\s*(?<!~)%(\[\d+\])?(d|s|q|v|t|f)/= "z~%$1$2~z"/g' "${hclfilepath}"

      perl -p -i -e 's/(?<!~)%(\[\d+\])?(d|s|q|v|t|f)/\ndata "abcd" "bdef" {\n fid = "z~%$1$2~z"\n}\n/gm' "${hclfilepath}"

      perl -0777pi -e 's/\n{3,}/\n\n/gm' "${hclfilepath}"
      perl -0777pi -e 's/( +[a-z_0-9]+\s*=*\s{)\n\n( +[a-z_0-9]+\s*=*\s{)/$1\n$2/g' "${hclfilepath}"
      perl -0777pi -e 's/( +[a-z_0-9]+\s*=*\s{)\n\n( +[a-z_0-9]+\s*=*\s{)/$1\n$2/g' "${hclfilepath}"
      perl -0777pi -e 's/( +[a-z_0-9]+\s*=*\s{)\n\n( +[a-z_0-9]+\s*=*\s{)/$1\n$2/g' "${hclfilepath}"
      perl -0777pi -e 's/( +[a-z_0-9]+\s*=*\s{)\n\n( +[a-z_0-9]+\s*=*\s{)/$1\n$2/g' "${hclfilepath}"
      perl -0777pi -e 's/\n\s*\n(\s*}\s*)/\n$1/gm' "${hclfilepath}"
      perl -0777pi -e 's/\n\s*\n(\s*}\s*)/\n$1/gm' "${hclfilepath}"
      perl -0777pi -e 's/\n\s*\n(\s*}\s*)/\n$1/gm' "${hclfilepath}"
      perl -0777pi -e 's/\n\s*\n(\s*}\s*)/\n$1/gm' "${hclfilepath}"
      perl -0777pi -e 's/\n\s*\n(\s*\]\s*)/\n$1/gm' "${hclfilepath}"
      perl -0777pi -e 's/\n\s*\n(\s*\]\s*)/\n$1/gm' "${hclfilepath}"
      perl -0777pi -e 's/\n\s*\n(\s*\]\s*)/\n$1/gm' "${hclfilepath}"
      perl -0777pi -e 's/\n\s*\n(\s*\]\s*)/\n$1/gm' "${hclfilepath}"

      perl -p -i -e 's/##YAML##//g' "${hclfilepath}"

      local error_message=""
      error_message="$(terraform fmt 2>&1)"
      if [ "$?" -ne 0 ]; then
        ((error_count=error_count+1))
        local errorfilepath=$(printf "%s/%s_error_%0*d.%s" "${filedir}" "${filename_without_ext}" 3 "${error_count}" "txt")
        printf "FAIL! (Error file: %s)\n" "${errorfilepath}"
        cat "${hclfilepath}" > "${errorfilepath}"
        printf "---------------------------------------------------------\n" >> "${errorfilepath}"
        printf "Error: %s\n" "${error_message}" >> "${errorfilepath}"
      fi

      perl -0777pi -e 's/\n([\t ]*)data[\t ]*"abcd"[\t ]*"bdef"\s*{\s*fid[\t ]*=[\t ]*"z~([^~]+)~z"\s*}/$1$2/gms' "${hclfilepath}"
      perl -p -i -e 's/"z~([^~]+)~z"/$1/gm' "${hclfilepath}"
      perl -p -i -e 's/"~~~%([^~]+)~"/%$1/g' "${hclfilepath}"
      perl -p -i -e 's/~~%/%/g' "${hclfilepath}"
      perl -p -i -e 's/ÖÖÖÖÖ( +=[^#]+) #~([^\n]+)/$2$1/g' "${hclfilepath}"
      perl -p -i -e 's/ÖÖ( +=[^#]+) #~([^\n]+)/$2$1/g' "${hclfilepath}"

      cat "${hclfilepath}" >> "${newfilepath}"

      printf "%s\n" "${line}" >> "${newfilepath}"

      ((count_end=count_end+1))
    else
      whereto="${hclfilepath}"
      if [ "${state}" = "${IGNORE}" ]; then
        whereto="${newfilepath}"
      elif [ "${state}" = "${YAML}" ]; then
        whereto="${yamlfilepath}"
      elif [ "${state}" = "${JSON}" ]; then
        whereto="${jsonfilepath}"
      fi

      printf "%s\n" "${line}" >> "${whereto}"
    fi
  done < "${prefilepath}"

  # post process
  perl -p -i -e 's/[ ]*##NY_LINJE##/\n/g' "${newfilepath}"
  perl -p -i -e 's/\n[ \t]+/\n/g' "${newfilepath}"
  perl -0777pi -e 's/\n{3,}/\n\n/g' "${newfilepath}"
  perl -p -i -e 's/"\$-{([^}]+)}-"/"\${$1}"/g' "${newfilepath}"
  perl -p -i -e 's/"!\|!(.*)!\|!"/\`$1\`/g' "${newfilepath}"
  perl -p -i -e 's/"!\|!(.*)!\|!"/\`$1\`/g' "${newfilepath}"
  perl -0777pi -e 's/\`\n\n}/\`\n}/gm' "${newfilepath}"
  perl -0777pi -e 's/\n\n\`/\n\`/gm' "${newfilepath}"
  perl -0777pi -e 's/{\n\n([^{]*{)/{\n$1/gm' "${newfilepath}"
  perl -0777pi -e 's/}\nPOTATO\`/}\`/gm' "${newfilepath}"
  perl -0777pi -e 's/\n\n\Z/\n/gm' "${newfilepath}"

  perl -p -i -e 's/#ÖPPNAR_LOCKIGT#/{/g' "${newfilepath}"
  perl -p -i -e 's/#STÄNGT_LOCKIGT#/}/g' "${newfilepath}"

  perl -p -i -e 's/##YAML##//g' "${newfilepath}"

  # clean up
  if [ "${TERRAFORMAT_TEST_MODE}" -eq "${TEST_MODE_NOTTESTING}" ]; then
    rm -f "${prefilepath}" || true
    rm -f "${hclfilepath}" || true
    rm -f "${jsonfilepath}" || true
    rm -f "${yamlfilepath}" || true

    if [ ${error_count} -eq 0 ]; then
      rm -f "${filepath}" || true
      mv "${newfilepath}" "${filepath}"
    else
      rm -f "${newfilepath}"
    fi
  fi

  terraformat_debug "Begins: ${count_begin}"
  terraformat_debug "Ends: ${count_end}"

  if [ ${error_count} -eq 0 ]; then
    return 0
  else
    return 1
  fi
}

function terraformat_unit_tests() {
  local pre_mode="${TERRAFORMAT_TEST_MODE}"
  TERRAFORMAT_TEST_MODE="${TEST_MODE_NOTTESTING}" # ironic

  local failures=0
  local successes=0
  local tests=( format_*_test.go )
  for test in ${tests[@]}; do
    echo "Test: ${test}"
    local test_num=$(echo "${test}" | cut -d'_' -f 2)
    local expected="format_${test_num}_expected.go"
    local temp="format_${test_num}_temp.go"
    if [ ! -f "${expected}" ]; then
      printf "Error, no expected result file: %s\n" "${expected}"
      continue
    fi
    rm -f "${temp}"
    cp "${test}" "${temp}"
    terraformat "${temp}"
    cmp "${expected}" "${temp}"
    if [ "$?" -eq 0 ]; then
      printf "--- PASS: %s\n" "${test}"
      ((successes=successes+1))
      rm -f "${temp}"
    else
      printf "--- FAIL: %s\n" "${test}"
      ((failures=failures+1))
      mv "${temp}" "format_${test_num}_error.txt"
    fi
  done

  printf "%d Tests Passed, %d Tests Failed\n" "${successes}" "${failures}"

  TERRAFORMAT_TEST_MODE="${pre_mode}"
}
