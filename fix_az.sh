#!/bin/bash

local TEST_MODE_TESTING=1
local TEST_MODE_NOTTESTING=0
test_mode="${TEST_MODE_NOTTESTING}"

function fix_az_debug() {
  local debug_msg=$1
  if [ "${test_mode}" = "${TEST_MODE_TESTING}" ]; then
    echo "${debug_msg}"
  fi
}

function fix_az() {
  local filepath=$1
  printf "Fix: %s\n" "${filepath}"
  local filedir=$(dirname -- "$filepath")
  local filename=$(basename -- "$filepath")
  local extension="${filename##*.}"
  local filename_without_ext="${filename%.*}"
  local newfilepath="${filedir}/${filename_without_ext}_new.${extension}"

  fix_az_debug "${newfilepath}"
  rm -f "${newfilepath}" 2>&1 || true

  cp "${filepath}" "${newfilepath}"

  perl -0777pi -e 's/(availability_zone\s*=\s*)"us-west-2a"/$1data.aws_availability_zones.available.names[0]/gm' "${newfilepath}"
  perl -0777pi -e 's/(availability_zone\s*=\s*)"us-west-2b"/$1data.aws_availability_zones.available.names[1]/gm' "${newfilepath}"
  perl -0777pi -e 's/(availability_zone\s*=\s*)"us-west-2c"/$1data.aws_availability_zones.available.names[2]/gm' "${newfilepath}"
  perl -0777pi -e 's/(availability_zone\s*=\s*)"us-west-2d"/$1data.aws_availability_zones.available.names[3]/gm' "${newfilepath}"

  perl -0777pi -e 's/(return\s*)(fmt\.Sprintf\(\`[^\`]*data\.aws_availability_zones\.available\.names[^\`]*\`[^)]*\))/$1composeConfig(testAccAvailableAZsNoOptInConfig(), $2)/gm' "${newfilepath}"

  perl -0777pi -e 's/(fmt.Sprintf\(\`[^\`]*)data\s*"aws_availability_zones"\s*"[^"]*"\s*{\s*state\s*=\s*"available"\s*filter\s*{\s*name\s*=\s*"opt-in-status"\s*values\s*=\s*\["opt-in-not-required"\]\s*}\s*}\s*([^\`]*\`)/testAccAvailableAZsNoOptInConfig() + $1$2/gm' "${newfilepath}"
  perl -0777pi -e 's/return\s*(\`[^\`]*)data\s*"aws_availability_zones"\s*"[^"]*"\s*{\s*state\s*=\s*"available"\s*filter\s*{\s*name\s*=\s*"opt-in-status"\s*values\s*=\s*\["opt-in-not-required"\]\s*}\s*}\s*([^\`]*\`)/return testAccAvailableAZsNoOptInConfig() + $1$2/gm' "${newfilepath}"
  perl -0777pi -e 's/const\s*([a-zA-Z0-9_]+\s*=)\s*(\`[^\`]*)data\s*"aws_availability_zones"\s*"[^"]*"\s*{\s*state\s*=\s*"available"\s*filter\s*{\s*name\s*=\s*"opt-in-status"\s*values\s*=\s*\["opt-in-not-required"\]\s*}\s*}\s*([^\`]*\`)/var $1 testAccAvailableAZsNoOptInConfig() + $2$3/gm' "${newfilepath}"
  perl -0777pi -e 's/var\s*([a-zA-Z0-9_]+\s*=)\s*(\`[^\`]*)data\s*"aws_availability_zones"\s*"[^"]*"\s*{\s*state\s*=\s*"available"\s*filter\s*{\s*name\s*=\s*"opt-in-status"\s*values\s*=\s*\["opt-in-not-required"\]\s*}\s*}\s*([^\`]*\`)/var $1 testAccAvailableAZsNoOptInConfig() + $2$3/gm' "${newfilepath}"
  perl -0777pi -e 's/(data\.aws_availability_zones\.)[a-z0-9_]+\./$1available./gm' "${newfilepath}"
  
  if [ "${test_mode}" -ne "${TEST_MODE_TESTING}" ]; then
    rm -f "${filepath}" || true
    mv "${newfilepath}" "${filepath}"
  fi

}
