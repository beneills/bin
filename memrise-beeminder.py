#!/usr/bin/env python

#
# Copyright Ben Eills, 2012
#
# This software is licensed under the Creative Commons Attribution 3.0 Unported License
#   which may be read here: http://creativecommons.org/licenses/by/3.0/
#   or in the LICENSE file, which should be distributed with the distribution.
#
# Essentially, you may do anything with this software, provided that you attribute this
#   and any derivative works to the original author (Ben Eills)
#

#
# This script allows you to update your Beeminder profile with Memrise stats.
#
# I intend to split this up into a generic Beeminder data daemon, and a Memrise API PYthon wrapper
#   at some point, but this way was more expedient.
#


import argparse
import glob
import os
import os.path
import ConfigParser
import urllib
import urllib2
import json
import time

CONFIG_DEFAULT = os.path.expanduser('~/.memrise-beeminder.config')
DATABASE_DEFAULT = os.path.expanduser('~/.memrise-beeminder.db')
TOTAL_COUNT_URL = 'http://www.memrise.com/api/1.0/itemuser/?format=json&user__username={0}'
DATAPOINT_ADD_URL = 'https://www.beeminder.com/api/v1/users/{0}/goals/{1}/datapoints.json?auth_token={2}'
COMMENT_DEFAULT = 'Data added by memrise-beeminder Python script. Repo: https://github.com/beneills/memrise-beeminder'

class BeeminderSession(object):
    def __init__(self, username, auth_token):
        self.username = username
        self.auth_token = auth_token
    def add_words(self, goal_slug, num_words, timeout=10):
        """
        Add a new datapoint with the current time, etc.
        """
        url = DATAPOINT_ADD_URL.format(self.username, goal_slug, self.auth_token)
        data = { 'timestamp' : str(int(time.time())),
                 'value' : str(num_words),
                 'comment' : COMMENT_DEFAULT }
        urllib2.urlopen(url, urllib.urlencode(data), timeout)

def fetch_total_count(username):
    json = fetch_json_data(TOTAL_COUNT_URL.format(username))
    return json['meta']['total_count']
    
def do_monitor_totalcount(username, database, beeminder_session, goal_slug):
    old_count = int(database.readline())
    # TODO: Is deleting words possible?  This would break things is so...
    new_count = fetch_total_count(username)
    delta = new_count - old_count
    if delta > 0:
        print "Found {0} new words.  Uploading to Beeminder...".format(delta),
        beeminder_session.add_words(goal_slug, delta)
        print "done."
        print "Updating local database...",
        database.seek(0)
        database.write(str(new_count))
        database.truncate()
        database.close()
    else:
        print "Found no new words.  Exiting cleanly."

def fetch_json_data(url, timeout=10):
    #DEBUG print "Fetching: {0}".format(url)
    result = urllib2.urlopen(url, None, timeout)
    return json.load(result)

def init_database(database_file, config):    
    print "New database file.  Initializing...",
    database_file.write(str(fetch_total_count(config.get('memrise', 'username'))))
    database_file.seek(0)
    print "done."

def load_config(f):
    """
    Parse config from file, and validate supplied data.
    """
    config = ConfigParser.RawConfigParser()
    config.readfp(f)
    # Mininum required data.  Raises exception if non-existent.
    config.get('memrise', 'username')
    config.get('beeminder', 'username')
    config.get('beeminder', 'auth_token')
    config.get('beeminder', 'goal_slug')
    return config

def cleanup(database_file, config_file):
    database_file.close()
    config_file.close()

def main():
    parser = argparse.ArgumentParser(description='Check Memrise for data and possibly upload to Beeminder.')
    parser.add_argument('-c', '--config-file', metavar='FILENAME', type=argparse.FileType('r'),
                        help='The config file containing your settings.  A default one is included in the distribution.')
    parser.add_argument('-d', '--database-file', metavar='FILENAME', type=argparse.FileType('r+'),
                        help='The database file to store persistent data in (e.g. we find newly learned words by monitoring total word count)')
    args = parser.parse_args()
    if not args.config_file:
        if os.path.exists(CONFIG_DEFAULT):
            args.config_file = open(CONFIG_DEFAULT, 'r')
        else:
            exit('Error: No config file specified and no default config in {0}'.format(CONFIG_DEFAULT))
    config = load_config(args.config_file)

    if not args.database_file:
        if not os.path.exists(DATABASE_DEFAULT):
            print "Database file not specified, and default doesn't exist. Creating..."
            args.database_file = open(DATABASE_DEFAULT, 'w+')
            init_database(args.database_file, config)
        else:
            args.database_file = open(DATABASE_DEFAULT, 'r+')
    else:
        print os.fstat(args.database_file.fileno())
        if os.fstat(args.database_file.fileno()).st_size == 0:
            init_database(args.database_file, config)

    b = BeeminderSession(config.get('beeminder', 'username'), config.get('beeminder', 'auth_token'))
    # Here we hardcode total_count monitoring, since the API isn't that great, and what I hoped to do seems impossible (without HTML scraping...)
    do_monitor_totalcount(config.get('memrise', 'username'), args.database_file, b, config.get('beeminder', 'goal_slug'))
    cleanup(args.database_file, args.config_file)

if __name__ == '__main__':
    main()
