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
HTTP_HOST="localhost:8500"

curl_true () {
  curl $@ 2>/dev/null | grep 'true' >/dev/null 2>&1
}

session_create_persist () {
  [ "$#" -eq "1" ] || return 1
  curl -X PUT -d "{ \"Name\": \"$1\", \"Checks\": [ ] }" "http://$HTTP_HOST/v1/session/create" 2>/dev/null | sed 's/.*"ID":"\([^"]*\)"}.*/\1/'
}

session_destroy () {
  [ "$#" -eq "1" ] || return 1
  curl_true -X PUT "http://$HTTP_HOST/v1/session/destroy/$1"
}

lock () {
  [ "$#" -eq "3" ] || return 1
  curl_true -X PUT "http://$HTTP_HOST/v1/kv/$2?$1=$3"
}

wait_on_key () {
  [ "$#" -eq "2" ] || return 1
  curl "http://$HTTP_HOST/v1/kv/$1?index=$2&wait=" 2>/dev/null | sed 's/.*"ModifyIndex":\([^,]*\),.*/\1/'
}
