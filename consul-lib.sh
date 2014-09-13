#!/bin/sh
################################################################################
# Copyright (c) 2014 William A. Kennington III
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
################################################################################

# Global session stuff
HTTP_HOST=${HTTP_HOST:-localhost:8500}

# Test for dependencies
if ! curl --help >/dev/null 2>&1; then
  echo "Could not execute curl. Maybe it is not installed?"
  exit 1
fi

curl_true () {
  local CURL_ARGS
  local CURL_OUT

  CURL_ARGS=$@

  CURL_OUT="$(curl $CURL_ARGS 2>/dev/null)" || return $?
  echo "$CURL_OUT" | grep 'true' >/dev/null 2>&1
}

curl_sed () {
  local CURL_ARGS
  local CURL_OUT
  local SED_IN

  SED_IN="'$1'"
  shift 1
  CURL_ARGS=$@

  CURL_OUT="$(eval curl $CURL_ARGS 2>/dev/null)" || return $?
  echo "$CURL_OUT" | eval sed "$SED_IN"
  exit 0
}

session_create_persist () {
  local CURL_OUT
  local DATA
  local SED_EXPR
  local SESSION_NAME
  local URL

  [ "$#" -eq "1" ] || return 1
  SESSION_NAME="$1"

  SED_EXPR='s/.*"ID":"\([^"]*\)"}.*/\1/'
  URL="'http://$HTTP_HOST/v1/session/create'"
  DATA="'{ \"Name\": \"$SESSION_NAME\", \"Checks\": [ ] }'"

  CURL_OUT="$(curl_sed "$SED_EXPR" -X PUT -d "$DATA" "$URL")" || return $?
  [ -z "$CURL_OUT" ] && return 1
  echo "$CURL_OUT"
}

session_destroy () {
  local SESSION_ID

  [ "$#" -eq "1" ] || return 1
  SESSION_ID="$1"

  curl_true -X PUT "http://$HTTP_HOST/v1/session/destroy/$SESSION_ID"
}

lock () {
  local KEY
  local LOCK_ARG
  local SESSION_ID

  [ "$#" -eq "3" ] || return 1
  LOCK_ARG="$1"
  KEY="$2"
  SESSION_ID="$3"

  curl_true -X PUT "http://$HTTP_HOST/v1/kv/$KEY?$LOCK_ARG=$SESSION_ID"
}

wait_on_key () {
  local CURL_OUT
  local INDEX
  local KEY
  local SED_EXPR
  local URL

  [ "$#" -eq "2" ] || return 1
  KEY="$1"
  INDEX="$2"

  SED_EXPR='s/.*"ModifyIndex":\([^,]*\),.*/\1/'
  URL="'http://$HTTP_HOST/v1/kv/$KEY?index=$INDEX&wait='"

  CURL_OUT="$(curl_sed "$SED_EXPR" "$URL")" || return $?
  [ -z "$CURL_OUT" ] && return 1
  echo "$CURL_OUT"
}
