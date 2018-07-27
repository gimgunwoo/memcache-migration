# memcache-migration
This script will let you dump key value pairs from one memcache server, add them to a new one.

## Requirements
* libmemcached-tools is required in the new memcache server
* memcached must be running in both servers before running this script
* This script must run in the new server

## Example
`sudo ./memcache_import.sh <old server ip address>`
