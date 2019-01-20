#!/bin/sh

# The script is a work in progress and some portions of the script may not work yet.

# Simple script to clear log files I have setup.

# Variables
reload_ufw_log="/home/matthew/logs/cronlog_reloadufw.log"
update_log="/home/matthew/logs/cronlog_update.log"
send_ip_address_log="/home/matthew/logs/cronlog_send_ip_address.log"
freedns_log="/home/matthew/logs/freedns_matthewmiller_us_to.log"
email_vpn_connections_log="/home/matthew/logs/get_email_from_vpn_connections.log"

# Script to delete logs
/usr/bin/find "${reload_ufw_log}" -mtime +30 -delete
/usr/bin/find "${update_log}" -mtime +30 -delete
/usr/bin/find "${send_ip_address_log}" -mtime +30 -delete
/usr/bin/find "${freedns_log}" -mtime +30 -delete
/usr/bin/find "${email_vpn_connections_log}" -mtime +30 -delete

# MIT License

# Copyright (c) 2019 Matthew David Miller

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
